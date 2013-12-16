//
//  AsyncMethod.h
//  SerializedTasks
//
//  Created by Eric McGary on 12/5/13.
//  Copyright (c) 2013 Eric McGary. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const AsyncMethodErrorDomain;

typedef enum {
    AsyncMethodErrorUnresponsiveSelector
} AsyncMethodErrorCodes;

@interface RLAsyncMethod : NSObject

@property (nonatomic) SEL method;
@property (nonatomic) id context;

+ (RLAsyncMethod*) context:(id)context method:(SEL) method;

- (void) execute:(void(^)(NSError* err)) callback;
- (void) execute:(void(^)(NSError* err, id data)) callback data:(id) data;

@end
