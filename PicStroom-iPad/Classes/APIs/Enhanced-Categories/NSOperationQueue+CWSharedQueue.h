//
//  NSOperationQueue+CWSharedQueue.h
//  PicStroom
//
//  Created by Damien Glancy on 18/02/2011.
//  Copyright 2011 Damien Glancy & Jeroen Hermkens. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSOperationQueue (SharedQueue)

/*!
 * Returns the shared NSOperationQueue instance. A shared instance with max
 * concurent operations set to CW_DEFAULT_OPERATION_COUNT will be created if no
 * shared instance has previously been set, or created.
 *
 * @result a shared NSOperationQueue instance.
 */
+(NSOperationQueue*)sharedOperationQueue;

/*!
 * Set the shared NSOperationQueue instance.
 * 
 * @param operationQueue the new shared NSOperationQueue instance.
 */
+(void)setSharedOperationQueue:(NSOperationQueue*)operationQueue;

@end


@interface NSObject (CWSharedQueue)

/*!
 * Invokes a method of the receiver on a new background queue.
 *
 * @param aSelector A selector that identifies the method to invoke. 
 *									The method should not have a significant return value and 
 *									should take a single argument of type id, or no arguments.
 * @param arg The argument to pass to the method when it is invoked. 
 *            Pass nil if the method does not take an argument.
 * @result an autoreleased NSInvocationOperation instance.
 *			   Can be used to setup dependencies.
 */
-(NSInvocationOperation*)performSelectorInBackgroundQueue:(SEL)aSelector withObject:(id)arg;


-(NSInvocationOperation*)performSelectorInBackgroundQueue:(SEL)aSelector withObject:(id)arg withQueuePriority:(NSOperationQueuePriority)priority;

@end