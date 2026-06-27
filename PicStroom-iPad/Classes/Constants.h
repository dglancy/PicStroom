//
//  Constants.h
//  PicStroom
//
//  Created by Damien Glancy on 23/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

typedef enum StroomStates {
	StroomStateNew, StroomStateUptodate, StroomStateUpdatesAvailable, StroomStateTitleChanged, StroomStateUpdating, StroomStateNewUpdating, StroomStateQueued, StroomStateNothingToUpdate
}
StroomState;

typedef enum StroomTypes {
	StroomTypeRSS, StroomTypeDropbox, StroomTypeStarred
}
StroomTypes;

typedef enum UserHappiness {
	UserNoHappiness, UserHappyOutstanding, UserHappyILikeIt, UserHappyCanBeBetter, UserHappyIWontReturn
}
UserHappiness;

typedef enum PictureOrientation {
	PictureLandscape, PicturePortrait
}
PictureOrientation;

typedef enum PictureSource {
	PictureFromWeb, PictureFromDropbox
}
PictureSource;

typedef enum TranslucentNotificationType {
	dropboxNotificationType=1, albumNotificationType, streamAddedNotificationType, errorNotificationType, slideShowStartType, slideShowStopType, slideShowLoopType, starAddedType, starRemovedType, instapaperSavedType
}
translucentNotificationType;

typedef enum ToolbarPosition {
	ToolbarNone, ToolbarRight, ToolbarLeft, ToolbarBottom
}
ToolbarPosition;

#warning TURN OFF DEBUG_MODE
#define DEBUG_MODE

/* Pro Version */
//#define PICSTROOM_PRO_VERSION                           YES
//#define PICSTROOM_VERSION                               @"Version 1.3 PRO"
//#define FLURRY_APP_KEY @"2IX6DHBMUXJJBHQXWUJ1" /* PRODUCTION KEY FOR PICSTROOM PRO IPAD*/
/* END of Pro Version */

/* IAP Version */
#define PICSTROOM_PRO_VERSION                               NO
#define PICSTROOM_VERSION                                   @"Version 1.3"
//#define FLURRY_APP_KEY @"7R1VI6XYCPM5IV22CUEN" /* PRODUCTION KEY FOR PICSTROOM IPAD*/
/* END of IAP Version */

/* Test Version */
#warning TEST FLURRY KEY -- REPLACE BEFORE PRODUCTION BUILD
#define FLURRY_APP_KEY                                      @"8PNF6LWBG24P82WSGXFJ" /* TEST KEY -- REPLACE BEFORE PRODUCTION BUILD */
/* END of Test Version */

#define DEFAULT_OPERATION_COUNT                             3

#define USER_AGENT                                          @"Mozilla/5.0 (compatible; PicStroom; iPad; http://www.picstroom.com)"

#define DROPBOX_KEY                                         @"ddsnt8la17y9j2c"
#define DROPBOX_SECRET                                      @"avacrc248g6psyk"

#define INSTAPAPER_KEY                                      @"h0gW54YxGwKojXRQQ46dvuOeo4MQgHn4TcWpCdXeYjYWuL2T4q"
#define INSTAPAPER_SECRET                                   @"bdJXNOuwmvx3mxOdBCoyE4vvMLPUgqMXkf3GmRlOv14l4rsdsU"

#define GALLERY_URL                                         @"http://data.picstroom.com/gallery-strooms.plist"
#define INITIAL_STROOMS_URL                                 @"http://data.picstroom.com/initial-strooms.plist"      // IAP version
//#define INITIAL_STROOMS_URL                                 @"http://data.picstroom.com/initial-strooms-pro.plist"  //Pro version
#define INTERNAL_STARRED_STROOM_URL                         @"http://data.picstroom.com/starred-pictures-damo"

#define SYNC_TIMER_IN_SECS                                  600
#define SYNC_TIMEOUT_IN_SECS                                60
#define MIN_FREE_DISK_STORAGE_IN_BYTES                      20971520 // 20MB

#define UNLIMITED_STROOMS_THRESHOLD                         3
#define UNLIMITED_STROOMS_PRODUCT_ID                        @"nl.hetissimpel.unlimitedstreams"

//keychain
#define INSTAPAPER_USER_OAUTH_TOKEN_SECRET_KEYCHAIN_KEY     @"INSTAPAPER_USER_OAUTH_TOKEN_SECRET_KEYCHAIN"
#define UNLIMITED_STROOMS_KEYCHAIN_KEY                      @"US"
#define UNLIMITED_STROOMS_KEYCHAIN_VALUE                    @"DAMIEN"

#define MIN_IMAGE_HEIGHT                                    150
#define CONTROL_BAR_WIDTH_PT                                60
#define PICTURE_HEIGHT_PT                                   120
#define SPACER_HEIGHT_PT                                    19

#define SETTINGS_PANEL_WIDTH_PT                             500
#define SETTINGS_PANEL_HEIGHT_PT                            600

#define SPACER_BETWEEN_STROOM_IMAGES_PT                     1
#define PADDING                                             20

#define LIMIT_NUM_OF_STROOMS_ADDED_FROM_GALLERY_AT_ONCE     7
#define TARGET_NUM_OF_STROOMS_ON_SCREEN                     7 // always +1 for button stroom

#define TOOLBAR_NUM_OF_ICONS                                8
#define TOOLBAR_SPACER_SIZE_PT                              2
#define TOOLBAR_ICON_HEIGHT_PT                              60
#define TOOLBAR_ICON_WIDTH_PT                               60

#define TRANSLUCENT_NOTIFICATION_VIEW_HEIGHT                300
#define TRANSLUCENT_NOTIFICATION_VIEW_WIDTH                 300
#define TRANSLUCENT_NOTIFICATION_VIEW_CORNER_RADIUS         10

#define ENTITY_STROOM                                       @"Stroom"
#define ENTITY_ENTRY                                        @"Entry"
#define ENTITY_PICTURE                                      @"Picture"
#define ENTITY_METADATA                                     @"Metadata"

#define STANDARD_FONT                                       @"HelveticaNeue"
#define STANDARD_FONT_SIZE                                  14.0
#define BOLD_FONT                                           @"HelveticaNeue-Bold"

#define NOTIF_SiteScan                                      @"NOTIF_SiteScan"
#define NOTIF_SiteImageScan                                 @"NOTIF_SiteImageScan"
#define NOTIF_NewStroom                                     @"NOTIF_NewStroom"
#define NOTIF_SYNC_START_STROOM                             @"NOTIF_SYNC_START_STROOM"
#define NOTIF_SYNC_END_STROOM                               @"NOTIF_SYNC_END_STROOM"
#define NOTIF_SYNC_CANCEL_SYNC_STROOM                       @"NOTIF_SYNC_CANCEL_SYNC_STROOM"
#define NOTIF_SYNC_NEW_PICTURE_FOUND                        @"NOTIF_SYNC_NEW_PICTURE_FOUND"
#define NOTIF_SYNC_PICTURE_REMOVED                          @"NOTIF_SYNC_PICTURE_REMOVED"
#define NOTIF_APP_STORE_PRODUCT_LIST_FETCHED                @"NOTIF_APP_STORE_PRODUCT_LIST_FETCHED"
#define NOTIF_IN_APP_PURCHASE_TX_SUCCESS                    @"NOTIF_IN_APP_PURCHASE_TX_SUCCESS"
#define NOTIF_IN_APP_PURCHASE_TX_FAIL                       @"NOTIF_IN_APP_PURCHASE_TX_FAIL"
#define NOTIF_IN_APP_PURCHASE_TX_CANCELLED                  @"NOTIF_IN_APP_PURCHASE_TX_CANCELLED"

#define BLANK_STRING                                        @""

// FLURRY
#define FLURRY_ADD_WEB_STROOM                               @"EVENT_ADD_WEB_STROOM"
#define FLURRY_REMOVE_WEB_STROOM                            @"EVENT_REMOVE_WEB_STROOM"
#define FLURRY_ADD_DROPBOX_STROOM                           @"EVENT_ADD_DROPBOX_STROOM"
#define FLURRY_BROWSE_IN_APP_PURCHASE_SCREEN                @"EVENT_BROWSE_IN_APP_PURCHASE_SCREEN"
#define FLURRY_COMPLETE_IN_APP_PURCHASE                     @"COMPLETE_IN_APP_PURCHASE"
#define FLURRY_REMOVE_DROPBOX_STROOM                        @"EVENT_REMOVE_DROPBOX_STROOM"
#define FLURRY_EVENT_LINK_DROPBOX                           @"EVENT_LINK_DROPBOX"
#define FLURRY_EVENT_UNLINK_DROPBOX                         @"EVENT_UNLINK_DROPBOX"
#define FLURRY_HAPPY_LEVEL                                  @"EVENT_USER_HAPPY_LVL"
#define FLURRY_SYNC_STROOM                                  @"EVENT_SYNC_STROOM"
#define FLURRY_BROWSE_GALLERY                               @"EVENT_BROWSE_GALLERY"
#define FLURRY_ADDING_SYSTEM_STROOMS                        @"EVENT_ADDING_SYSTEM_STROOMS"
#define FLURRY_ADD_GALLERY_WEB_STROOM                       @"EVENT_ADDING_GALLERY_WEB_STROOM"
#define FLURRY_IN_APP_PURCHASE_UNLIMITED_STROOMS            @"EVENT_IN_APP_PURCHASE_UNLIMITED_STROOMS"
#define FLURRY_EMBD_BROWSER_LAUNCHED                        @"EVENT_EMBD_BROWSER_LAUNCHED"
#define FLURRY_NO_DISK_STORAGE_WARNING_SHOWN                @"EVENT_NO_DISK_STORAGE_WARNING_SHOWN"
#define FLURRY_NO_DISK_STORAGE_STATE_DETECTED               @"EVENT_NO_DISK_STORAGE_STATE_DETECTED"
#define FLURRY_ABOUT_BOX_DISPLAYED                          @"EVENT_ABOUT_BOX_DISPLAYED"
#define FLURRY_STATS_NUMBER_OF_PICS_ON_STARTUP              @"EVENT_STATS_NUMBER_OF_PICS_ON_STARTUP"
#define FLURRY_STATS_NUMBER_OF_STREAMS_ON_STARTUP           @"EVENT_STATS_NUMBER_OF_STREAMS_ON_STARTUP"
#define FLURRY_STATS_IN_APP_PURCHASE_DIALOG_SHOWN           @"EVENT_STATS_IN_APP_PURCHASE_DIALOG_SHOWN"
#define FLURRY_IAP_BUG_RESOLVED_FOR_USER                    @"EVENT_IAP_BUG_RESOLVED_FOR_USER"
#define FLURRY_STAR_IMAGE                                   @"EVENT_STAR_IMAGE"
#define FLURRY_UNSTAR_IMAGE                                 @"EVENT_UNSTAR_IMAGE"
#define FLURRY_SAVE_TO_LIBRARY                              @"EVENT_SAVE_TO_LIBRARY"
#define FLURRY_SAVE_TO_INSTAPAPER                           @"EVENT_SAVE_TO_INSTAPAPER"
#define FLURRY_LINK_INSTAPAPER                              @"EVENT_LINK_INSTAPAPER"
#define FLURRY_UNLINK_INSTAPAPER                            @"EVENT_UNLINK_INSTAPAPER"

// USER DEFAULTS
#define USER_DEFAULTS_USER_HAPPY_LEVEL                      @"USER_HAPPY_LEVEL"
#define USER_DEFAULTS_USER_ID                               @"USER_ID"
#define USER_DEFAULTS_DROPBOX_SAVE_FOLDER                   @"USER_DEFAULTS_DROPBOX_SAVE_FOLDER"
#define USER_DEFAULTS_DROPBOX_ACCOUNT_IN_USE                @"USER_DEFAULTS_DROPBOX_ACCOUNT_IN_USE"
#define USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM             @"USER_DEFAULTS_MAX_IMAGES_IN_EACH_STREAM"
#define USER_DEFAULTS_INSTAPAPER_USER_OAUTH_TOKEN           @"USER_DEFAULTS_INSTAPAPER_USER_OAUTH_TOKEN"

// METADATA KEYS
#define METADATA_STAR                                       @"MD_STAR"