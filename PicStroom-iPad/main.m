//
//  main.m - application entry point
//  PicStroom
//
//  Created by Damien Glancy on 01/03/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);

    [pool release];
    return retVal;
}
