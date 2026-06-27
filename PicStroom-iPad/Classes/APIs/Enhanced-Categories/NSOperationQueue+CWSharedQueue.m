//
//  NSOperationQueue+CWSharedQueue.m
//  PicStroom
//
//  Created by Damien Glancy on 18/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import "NSOperationQueue+CWSharedQueue.h"

@implementation NSOperationQueue (SharedQueue)

static NSOperationQueue* sharedOperationQueue = nil;

+(NSOperationQueue*)sharedOperationQueue; {
	if (sharedOperationQueue == nil) {
        sharedOperationQueue = [[NSOperationQueue alloc] init];
        [sharedOperationQueue setMaxConcurrentOperationCount:DEFAULT_OPERATION_COUNT];
    }
    return sharedOperationQueue;
}

+(void)setSharedOperationQueue:(NSOperationQueue*)operationQueue; {
	if (operationQueue != sharedOperationQueue) {
        [sharedOperationQueue release];
        sharedOperationQueue = [operationQueue retain];
    }
}

@end


@implementation NSObject (CWSharedQueue)

-(NSInvocationOperation*)performSelectorInBackgroundQueue:(SEL)aSelector withObject:(id)arg; {
    return [self performSelectorInBackgroundQueue:aSelector withObject:arg withQueuePriority:NSOperationQueuePriorityLow];
}

-(NSInvocationOperation*)performSelectorInBackgroundQueue:(SEL)aSelector withObject:(id)arg withQueuePriority:(NSOperationQueuePriority)priority {
	NSInvocationOperation* operation = [[NSInvocationOperation alloc] initWithTarget:self selector:aSelector object:arg];
    [operation setQueuePriority:priority];
    [operation addObserver:self forKeyPath:@"isCancelled" options:NSKeyValueObservingOptionNew context:nil];
    [[NSOperationQueue sharedOperationQueue] addOperation:operation];
	return [operation autorelease];  
}

@end