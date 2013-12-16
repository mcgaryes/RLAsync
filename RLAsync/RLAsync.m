//
//  RLAsync.m
//  RLAsync
//
//  Created by Eric McGary on 12/7/13.
//  Copyright (c) 2013 Eric McGary. All rights reserved.
//

#import "RLAsync.h"
#import "RLAsyncMethod.h"

typedef void (^SequenceCompletionBlock)(id data);
typedef void (^ParallelCompletionBlock)(void);
typedef void (^ErrorBlock)(NSError* error);
typedef void (^ProgressBlock)(NSInteger completed, NSInteger total);

typedef enum {
    RLAsyncParallel,
    RLAsyncSequence
} RLAsyncControlFlowType;

@interface RLAsync()

@property (nonatomic,strong) NSArray* methods;
@property (nonatomic) NSInteger curMethod;
@property (nonatomic) NSInteger completedMethods;

@property (nonatomic,strong) SequenceCompletionBlock sequenceCompeletionBlock;
@property (nonatomic,strong) ParallelCompletionBlock parallelCompeletionBlock;
@property (nonatomic,strong) ErrorBlock errorBlock;
@property (nonatomic,strong) ProgressBlock progressBlock;

@property (nonatomic) RLAsyncControlFlowType type;

@property (nonatomic, getter = isCanceled) BOOL canceled;
@property (nonatomic, getter = isRunning) BOOL running;

@end


@implementation RLAsync

#pragma mark - Public Class Methods

+ (RLAsync*) sequence:(NSArray*)methods
             complete:(void(^)(id data))complete
                error:(void(^)(NSError* err))error
{
    RLAsync* async = [[RLAsync alloc] init];
    async.methods = methods;
    async.curMethod = 0;
    async.sequenceCompeletionBlock = complete;
    async.errorBlock = error;
    async.type = RLAsyncSequence;
    return async;
}

+ (RLAsync*) sequence:(NSArray*)methods
             complete:(void(^)(id data))complete
                error:(void(^)(NSError* err))error
             progress:(void (^)(NSInteger, NSInteger))progress
{
    RLAsync* async = [RLAsync sequence:methods complete:complete error:error];
    async.progressBlock = progress;
    return async;
}

+ (RLAsync*) parallel:(NSArray *)methods
             complete:(void (^)(void))complete
                error:(void (^)(NSError *))error
{
    RLAsync* async = [[RLAsync alloc] init];
    async.methods = methods;
    async.completedMethods = 0;
    async.parallelCompeletionBlock = complete;
    async.errorBlock = error;
    async.type = RLAsyncParallel;
    return async;
}

+ (RLAsync*) parallel:(NSArray*) methods
             complete:(void(^)(void)) complete
                error:(void(^)(NSError* err)) error
             progress:(void(^)(NSInteger completed, NSInteger total)) progress
{
    RLAsync* async = [RLAsync parallel:methods complete:complete error:error];
    async.progressBlock = progress;
    return async;
}

#pragma mark - Public Instance Methods

-(void) run
{
    switch (_type) {
        case RLAsyncParallel:
            [self executeParallel];
            break;
        case RLAsyncSequence:
            [self executeSequence:[_methods objectAtIndex:_curMethod] data:nil];
            break;
    }
}

-(void) runWithData:(id)data
{
    switch (_type) {
        case RLAsyncParallel:
            [self executeParallel];
            break;
        case RLAsyncSequence:
            [self executeSequence:[_methods objectAtIndex:_curMethod] data:data];
            break;
    }
}

-(void) cancel
{
    if(_running) _canceled = YES;
}

#pragma mark - Private Instance Methods

-(void) executeSequence:(RLAsyncMethod*)method data:(id) data
{
    _running = YES;
    _canceled = NO;
    [method execute:^(NSError *err, id data) {
        if(_canceled) {
            _running = NO;
            return;
        }
        if(!err) {
            if(_curMethod != _methods.count-1) {
                _curMethod++;
                if(_progressBlock) _progressBlock(_curMethod, _methods.count);
                [self executeSequence:[_methods objectAtIndex:_curMethod] data:data];
            } else {
                _running = NO;
                if(_progressBlock) _progressBlock((_curMethod+1), _methods.count);
                _sequenceCompeletionBlock(data);
            }
        } else {
            _running = NO;
            _errorBlock(err);
        }
    } data:data];
}

-(void) executeParallel
{
    _running = YES;
    _canceled = NO;
    for (NSInteger i = 0; i<_methods.count; i++) {
        RLAsyncMethod* method = (RLAsyncMethod*)[_methods objectAtIndex:i];
        [method execute:^(NSError *err) {
            if(_canceled) {
                _running = NO;
                return;
            }
            if(!err) {
                _completedMethods++;
                if(_progressBlock) _progressBlock(_completedMethods, _methods.count);
                if(_completedMethods == _methods.count) {
                    _running = NO;
                    _parallelCompeletionBlock();
                }
            } else {
                _running = NO;
                _errorBlock(err);
            }
        }];
    }
}

@end