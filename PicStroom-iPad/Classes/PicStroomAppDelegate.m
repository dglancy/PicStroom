//
//  PicStroomAppDelegate.m
//  PicStroom
//
//  Created by Damien Glancy on 01/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

/*
 * Thanks to the following artists for helping me over the hump when things weren't working out.....
 *
 * Only Revolutions -- Biffy Clyro -- http://en.wikipedia.org/wiki/Only_Revolutions_(album) <<== special mention
 * James Blake -- James Blake -- http://en.wikipedia.org/wiki/James_Blake
 * Janelle Monáe -- The ArchAndroid -- http://en.wikipedia.org/wiki/Janelle_Monáe
 *
 */

#import "PicStroomAppDelegate.h"
#import "PicStroomViewController.h"

#import "PicStroomManager.h"
#import "PicStroomAddStroomManager.h"
#import "PicStroomSupervisor.h"
#import "PicStroomInAppPurchaseManager.h"

#import "NSOperationQueue+CWSharedQueue.h"

#import "DBSession.h"
#import "InstapaperKit.h"

@implementation PicStroomAppDelegate
@synthesize window;
@synthesize viewController;
@synthesize currentNetworkStatus;
@synthesize reachability;
@synthesize syncTimer;
@synthesize lastSyncTime;
@synthesize inAppPurchaseManager;
@synthesize managedObjectContext = __managedObjectContext;
@synthesize managedObjectModel = __managedObjectModel;
@synthesize persistentStoreCoordinator = __persistentStoreCoordinator;

static void RootUncaughtExceptionHandler(NSException *exception) {
    [FlurryAPI logError:@"Uncaught" message:@"Crash!" exception:exception];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Memory management
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
    // stop any running sync
    /*DebugLog(@"Low memory warning received. Stopping any ongoing sync operations.");
     * NSOperationQueue *operationQueue=[NSOperationQueue sharedOperationQueue];
     * [operationQueue cancelAllOperations];*/
}

- (void) dealloc {
    [viewController release];
    [window release];
    [inAppPurchaseManager release];
    [__managedObjectContext release];
    [__managedObjectModel release];
    [__persistentStoreCoordinator release];
    [super dealloc];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Application lifecycle
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (BOOL) application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSSetUncaughtExceptionHandler(&RootUncaughtExceptionHandler);

    /** NSURLCache configurations **/
    [[NSURLCache sharedURLCache] setMemoryCapacity:0];
    [[NSURLCache sharedURLCache] setDiskCapacity:0];

    /** FLURRY **/
    [FlurryAPI startSession:FLURRY_APP_KEY];
    NSString *userId = [[NSUserDefaults standardUserDefaults] stringForKey:USER_DEFAULTS_USER_ID];
    if (!userId) {
        // First load of the application
        userId = [[NSProcessInfo processInfo] globallyUniqueString];
        [[NSUserDefaults standardUserDefaults] setObject:userId forKey:USER_DEFAULTS_USER_ID];
        DebugLog(@"Generated a new userId: %@", userId);
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:0] forKey:USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM]; // 0 = unlimited (the default)
        viewController.firstAppLoad = YES;
    } else {
        viewController.firstAppLoad = NO;
    }
    [FlurryAPI setUserID:userId];
        
    /** Handle IAP bug introduced in v1.1 **/
    [self handleIAPbug:userId];
    
    /** Create Starred Images Stroom if required **/
    if (![PicStroomAddStroomManager isStarredStroomAvailable]) {
        [PicStroomAddStroomManager createStarredStroom];
    }
    
    /** DROPBOX **/
    DBSession *session = [[DBSession alloc] initWithConsumerKey:DROPBOX_KEY consumerSecret:DROPBOX_SECRET];
    // session.delegate = self; // DBSessionDelegate methods allow you to handle re-authenticating
    [DBSession setSharedSession:session];
    [session release];
    
    /** INSTAPAPER **/
    [IKEngine setOAuthConsumerKey:INSTAPAPER_KEY andConsumerSecret:INSTAPAPER_SECRET];

    /** IN APP PURCHASE **/
    //#warning REMOVE
    //[PicStroomInAppPurchaseManager licenseForUnlimitedStrooms];
    //[PicStroomInAppPurchaseManager unLicenseForUnlimitedStrooms];

    self.inAppPurchaseManager = [[[PicStroomInAppPurchaseManager alloc] init] autorelease];
    [inAppPurchaseManager loadStore];

    [self.window addSubview:viewController.view];
    [self.window makeKeyAndVisible];

    self.reachability = [Reachability reachabilityForInternetConnection];

    return YES;
}

- (void) applicationWillResignActive:(UIApplication *)application {
    NSOperationQueue *operationQueue = [NSOperationQueue sharedOperationQueue];

    DebugLog(@"Cancelling %d background operation(s)", [operationQueue operationCount]);
    [operationQueue cancelAllOperations];
    [reachability stopNotifier];
    [self.syncTimer invalidate];
    self.syncTimer = nil;
}

- (void) applicationDidBecomeActive:(UIApplication *)application {
    [viewController handleNetworkChange:nil];
    [reachability startNotifier];

    [self performSelector:@selector(sync) withObject:nil afterDelay:5.5];
    DebugLog(@"Application Delegate registering a %d sec timer for sync operations.", SYNC_TIMER_IN_SECS);
    self.syncTimer = [NSTimer scheduledTimerWithTimeInterval:SYNC_TIMER_IN_SECS target:self selector:@selector(sync) userInfo:nil repeats:YES];
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Sync
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) sync {
     //#warning - REMOVE REMOVE REMOVE
     //return;

    if (self.lastSyncTime == nil) {
        self.lastSyncTime = [NSDate date];
        DebugLog(@"Application Delegate firing a sync.");
        for (PicStroomSupervisor *stroomSupervisor in viewController.stroomSupervisors) {
            [stroomSupervisor startSyncInBackgroundQueue];
        }
    } else {
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:lastSyncTime];
        int hours = (int)interval / 3600;             // integer division to get the hours part
        int minutes = (interval - (hours * 3600)) / 60; // interval minus hours part (in seconds) divided by 60 yields minutes
        if (minutes >= 9) {
            DebugLog(@"Application Delegate firing a sync.");
            self.lastSyncTime = [NSDate date];
            for (PicStroomSupervisor *stroomSupervisor in viewController.stroomSupervisors) {
                [stroomSupervisor startSyncInBackgroundQueue];
            }
        } else {
            DebugLog(@"Application has already synced within the past 10 minutes so not scheduling a sync on this start.");
            // restart syncs for any streams that have justAddedMarker still set to YES
            for (PicStroomSupervisor *stroomSupervisor in self.viewController.stroomSupervisors) {
                if ([stroomSupervisor.stroom.justAddedMarker boolValue]) {
                    DebugLog(@"Restarting sync for just added stroom: %@", stroomSupervisor.stroom.title);
                    [stroomSupervisor startSyncInBackgroundQueue];
                }
            }
        }
    }
}

- (void) applicationWillTerminate:(UIApplication *)application {
    NSOperationQueue *operationQueue = [NSOperationQueue sharedOperationQueue];

    DebugLog(@"Cancelling %d background operation(s)", [operationQueue operationCount]);
    if ([operationQueue operationCount] > 0) {
        [operationQueue cancelAllOperations];
    }
    [reachability release];
    [self.syncTimer invalidate];
    self.syncTimer = nil;
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

// //////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Core Data stack
// //////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) saveContext {
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;

    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            DebugLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}

/**
 * Returns the managed object context for the application.
 * If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
    if (__managedObjectContext != nil) {
        return __managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        __managedObjectContext = [[NSManagedObjectContext alloc] init];
        [__managedObjectContext setUndoManager:nil]; // nil undo manager
        [__managedObjectContext setPersistentStoreCoordinator:coordinator];
        [__managedObjectContext setStalenessInterval:0.0];
    }
    return __managedObjectContext;
}

/**
 * Returns the managed object model for the application.
 * If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *) managedObjectModel {
    if (__managedObjectModel != nil) {
        return __managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"PicStroom" withExtension:@"momd"];
    __managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return __managedObjectModel;
}

/**
 * Returns the persistent store coordinator for the application.
 * If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {
    if (__persistentStoreCoordinator != nil) {
        return __persistentStoreCoordinator;
    }

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"picstroom.sqlite"];

    NSError *error = nil;
    __persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    if (![__persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        DebugLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }

    return __persistentStoreCoordinator;
}

- (NSURL *) applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)handleIAPbug:(NSString *)userId {
    if (!PICSTROOM_PRO_VERSION && ![PicStroomInAppPurchaseManager isLicensedForUnlimitedStrooms]) {
        NSArray *iapUsers = [NSArray arrayWithObjects:@"A1EF442C-D7E3-4636-90EC-E8C54983746C-4367-000005B0E0B62F7E",@"949284BA-83F4-47AD-AF9C-B1B6A8314029-1087-000001248DD7D956",@"D760F327-4E17-4C9F-88C0-D06E097E1000-2397-00000463E8EC4886",@"EA310FB8-0B68-4061-AE78-C6BE0D9BEFF5-3452-0000065F7D47E0F6",@"C5B07A2B-8EFE-46CD-8CBF-B9C90E3A4B76-77-000000043D44C33F",@"F9DF5874-8F78-4AEC-A41D-76CCB3CEB281-324-000000130349EBC8",@"5A9E38EA-71A7-4C97-B683-6D46CBC8F267-265-00000092752C20D1",@"7135B024-76DD-469C-87FB-12A317392022-392-00000144F8E787DF",@"EB630F2F-818B-47AB-A1AE-54F29A62CB25-526-00000078F3D2979D",@"BA2166B0-B14F-4E7A-8A4F-B8961A960EEA-364-0000010C41353C84",@"DB68FB28-162D-4D42-B560-EB5786CF8EF9-3621-0000035189F2E8BA",@"FA388E7C-3545-4F6C-908F-8DEDFD123FC2-274-00000072DFEAB664",@"3AC96CC6-A4D6-4F72-978E-F1232B2AD169-706-0000014BAF0DAFC0",@"A1303D60-94D6-40BA-93A9-BDF3D00DC6DA-5583-0000006675440102",@"2343AA32-C7EF-4A09-9318-E0A1B7E1677C-3372-0000060F70AEF086",@"A8301644-0BA9-426D-A783-216E18172F84-110-0000002F2D45E109",@"C25F7146-D36B-4017-A883-5F36B21D7A30-3713-0000029F723A098E",@"6BFE6130-25B1-47EE-99E8-497C608E8BA7-667-00000157393C895A",@"12FC9281-8E46-453A-AAEA-23BAB38720EB-7183-00000747A63735A2",@"A5A091E0-2549-4D9D-A625-B265F4B39F80-629-0000016083E8A2DD",@"33222C72-83BE-4577-AD4C-B759FD4F82AD-858-000001A232B3755D",@"1C32797C-075C-4163-8352-97A7D6368DA1-795-0000007AA76F1685",@"5BC5035B-405B-4B8D-AAC6-0041D6EBAE97-174-000000288D91936D",@"67659538-51FF-44F8-9F78-9389B425744B-185-0000002CFD87C0A2",@"8A331B61-6CBE-4577-AE19-FF795349B24C-4157-00000714C4C6A7C2",@"0B368035-9BAD-42D5-98A7-4EF38E94B9C8-1988-00000297CB74AB83",@"D055E677-F754-4BCC-8513-BCC610204F20-8422-000011B0926B6C2E",@"4CF1CF89-8997-497D-BE82-D25A48AE43D8-152-000000B7D2003666",@"CFB32F11-9EDA-4743-801D-543ECA0A77DA-2124-000005D845F79AE5",@"62099095-C1FB-418B-BCA0-D8B4CC5CF47A-1334-0000029C498F78FC",@"723C41B1-9568-46B0-8492-834B33CC8CB2-2941-0000017D3706264F",@"353551D6-671E-4D45-B69F-EC2D1CDA66FB-1759-000002F93B28F32D",@"93DBA959-FB42-41A0-94C7-ECA910CE5110-1506-0000024969B1BE8B",@"ADE8D66B-C6C2-4E94-997E-F0AA29667F69-881-00000247B0B1D15E",@"4CAB11CB-FB50-43ED-8A6E-745A63FB3E62-1975-000001E7037792A4",@"802468BB-CB80-40B7-B04B-CC08CBAA8B35-4674-00000553EFD4270C",@"24129512-2FAD-46A7-BF55-310709B5BD74-1282-000001BD75763518",@"59C66564-F6F4-4B1E-999F-5D5CE3831827-1883-000002F70D60DB17",@"4CE40A7E-A68C-4BCE-B4F3-D4A471050944-8378-0000146ACAD5CCAD",@"B146A9D5-9A23-4087-80A8-5BC4055B14C9-822-000002116D721431",@"1D3AAA95-6330-4F9F-8DCA-3FF4ACC08051-2646-000000D89BF8814B",@"9E2868CF-F14C-4821-83AD-43183F10C9A5-2070-0000011394160FBE",@"4D352EC2-88DF-4219-96D2-A801", @"140B2768-3793-0000059C4ECA3167",@"DB69F575-CD02-4B41-80E8-935106F5600D-6218-000016A6E44DC9E2",@"8375CC0B-8351-4C99-B3EB-DD014D1FCFE4-2320-0000026E3277CFB1",@"4D0A0D31-4C14-4E4D-910A-3952C6193FC7-1115-0000040780CFFAC2",@"3DD0C095-C7DA-412C-A5C8-0E18F76C7108-6035-00000471813CAF9B",@"05770723-1A01-42D1-A9EA-9E1F1225ECAB-10264-00000B95CFA4DAF5",@"F37A6A44-CF24-4589-BEA5-F95D860E389D-7516-000006BE942593F4",@"861B340A-591D-44C7-9185-9A5534BBB7DE-4605-00000E0FDF6E3D73",@"406EE704-6C6E-4661-B97D-4D61914E7491-56-00000000523C1770",@"AF281346-84E5-4D47-94F1-585D685C03F9-365-000000DE5DDB1A11",@"4FF90A37-C5D0-4F1B-BD2A-3720A0A6D883-1745-00000285B4DF1414",@"01F7E304-A8D1-43F7-9586-E59A4FF8AC90-96-0000004E43764AC4",@"2C21E87C-DF3C-40E2-83CA-798AA365443B-857-000000CAE5E356EA",@"01DFA33B-2B65-4719-A249-E16877DB2090-8031-000008776E5AD75B",@"F44931EC-A329-4494-9315-B280753DB0C8-9452-0000091D1605D5D7",@"381DA163-A53B-45BE-8B4C-ADF4EED47A81-823-00000142334EB180",@"552439A7-70EE-4E0B-A8B9-ABA05E72892C-3538-0000021A4CD298C8",@"BDA522F9-515A-4350-A767-2C51EE15DAAB-2143-000001807E96F8A7",@"54B5E7CA-E9D0-4AC7-A470-F50782CB76CE-481-00000209E7E513C2",@"50842DC4-031B-4197-BD2C-F691FED6F4BB-12572-0000180928522D58",@"77CB45ED-EFBA-4711-8082-4FA85663B35E-5256-00000579892F9952",@"0E6338D5-193F-4006-842B-2231A15C7DCB-1044-000001A2EB7E0761",@"42DC4E5B-F21F-44AC-BCA2-5EE595EB570E-1430-00000222222D2C62",@"F78B27D8-E975-4248-8020-6599EED3E4EC-311-000001412BE2DFCF",@"CD7ECD0D-0EBA-461D-9C0A-ACBD0B5716CA-7704-0000051BA6094FB5",@"13163902-FFB4-4C7A-AE80-97DD9AF6967A-6241-00000AFDCD0E021F",@"91DABBD0-50EF-4386-A96E-E75303900796-1835-000002C340D1351C",@"BB55145B-D23F-4E51-BAE9-CEF0F53B27BC-112-00000007194BF9AF",@"217584B8-09DF-43DC-9199-ACD96214297C-9447-00000B06D8CB3A47",@"67B27E79-6F69-4E74-A610-C07BE289B26F-92-0000000335A6A449",@"28A8A5F6-A67C-498E-A54E-2AC96666E6EC-491-000001D8B8511EA0",@"49ACD67F-E506-4DC9-8EA7-B3B653151727-9104-0000077C78E807D1",@"9C94B790-6382-4DC6-B41D-31B6E37C6455-7381-000009C0D47B7025",@"A50C58A6-5496-44F5-9FF0-AF62FF87E5A9-1999-00000353BE7AFEE9",@"6F612D30-FB59-40C7-AD90-8E40D99B6A00-3665-0000050C809ED5D1",@"D2FE9F17-21D8-4197-AB18-2209877A74DF-413-000000386446A322",@"66B81107-B9CB-4659-BBBA-1B3125706798-1929-0000015953DB9F27",@"1BEE56A1-4414-4BA8-9834-612B04A10080-2243-00000554A346327F",@"406EE704-6C6E-4661-B97D-4D61914E7491-56-00000000523C1770",@"D9783C12-2939-42D2-B6E1-133E8AC2DDCB-962-0000045B01E6BDBC",@"A70FE947-F658-4B70-A594-DAB7D04652B7-5793-00000A7FF4944AE5",@"B42F8C94-15DE-4BFE-A0BA-7C62D14DF5F5-887-00000148BE7FC3B6",@"9A85007C-EB23-4E0E-8C9F-2273A4846709-506-0000007CBF8BB689",@"010C4EF2-D225-49B9-9AA3-9BB166973830-5360-00000820D7581546",@"E7787B63-EFF2-4BE0-B518-802EBC2DAE15-164-0000000C296592C0",@"1FE49C77-1890-46F2-B489-89E0B5288C03-816-000000DBE8F56418",@"C2C9706D-A20A-46BC-8F9C-02E965B116DF-92-00000045FED70371",@"B6DE93E2-5FC1-4AE1-B7AC-EF24A2F4F619-3742-00000FA9C280AC0E",@"5F0AB7EC-96A1-4AB2-B938-D21291AE53FC-6476-00000A89A51A3B25",@"57E2BD3A-5D6A-47CB-A70F-2D4D2AA37C5D-7365-000004ACFF90B134",@"B05E48BC-E658-4E00-8A60-C1748F7A57AA-99-0000000EB316FBF5",@"F6611998-178E-4383-8F9A-B67DAF6F6E54-524-000000B9CB2AFF17",@"4D457DC9-996B-4328-B988-FBFAAD010592-8323-00000CB1C34A56B8",@"5D67A34C-BE12-4207-84DD-0018B4C09D42-529-0000032BAACAD938",@"C11FC033-EF2F-4E3D-8A56-7ACE3FA694A5-1679-0000043056876546",@"90DD4E4B-8CB2-428C-8E47-F78D92E869C3-126-00000051A8FB62EA",@"B0FA9B37-C0DD-476C-91AC-7190827E7D0D-2899-000006C6E83F6EAC",@"949284BA-83F4-47AD-AF9C-B1B6A8314029-1087-000001248DD7D956",@"A1EF442C-D7E3-4636-90EC-E8C54983746C-4367-000005B0E0B62F7E", nil];
        if ([iapUsers containsObject:userId]) {
            [PicStroomInAppPurchaseManager licenseForUnlimitedStrooms];
            [FlurryAPI logEvent:FLURRY_IAP_BUG_RESOLVED_FOR_USER];
        }
    }
}

@end
