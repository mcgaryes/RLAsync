//
//  AsyncMethod.m
//  SerializedTasks
//
//  Created by Eric McGary on 12/5/13.
//  Copyright (c) 2013 Eric McGary. All rights reserved.
//

#import "RLAsyncMethod.h"

NSString *const AsyncMethodErrorDomain = @"AsyncMethodErrorDomain";
NSString *const UnresponsiveSelector = @"Unresponsive Selector";

@implementation RLAsyncMethod

+ (RLAsyncMethod*) context:(id)context method:(SEL) method
{
    RLAsyncMethod* asyncMethod = [[RLAsyncMethod alloc] init];
    asyncMethod.method = method;
    asyncMethod.context = context;
    return asyncMethod;
}

- (void) execute:(void(^)(NSError* err, id data))callback data:(id) data
{
    if([_context respondsToSelector:_method]) {
        NSMethodSignature* signature = [[_context class] instanceMethodSignatureForSelector:_method];
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        invocation.target = _context;
        invocation.selector = _method;
        [invocation setArgument:&callback atIndex:2];
        [invocation setArgument:&data atIndex:3];
        [invocation invoke];
    } else {
        callback([NSError errorWithDomain:AsyncMethodErrorDomain
                                     code:AsyncMethodErrorUnresponsiveSelector
                                 userInfo:@{ NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ %@",UnresponsiveSelector,NSStringFromSelector(_method)] }], nil);
    }
}

-(void) execute:(void (^)(NSError *))callback
{
    if([_context respondsToSelector:_method]) {
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[[_context class] instanceMethodSignatureForSelector:_method]];
        invocation.target = _context;
        invocation.selector = _method;
        [invocation setArgument:&callback atIndex:2];
        [invocation invoke];
    } else {
        callback([NSError errorWithDomain:AsyncMethodErrorDomain
                                     code:AsyncMethodErrorUnresponsiveSelector
                                 userInfo:@{ NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@ %@",UnresponsiveSelector,NSStringFromSelector(_method)] }]);
    }
}

@end
