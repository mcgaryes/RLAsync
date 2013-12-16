//
//  RLAsyncTests.m
//  RLAsyncTests
//
//  Created by Eric McGary on 12/7/13.
//  Copyright (c) 2013 Eric McGary. All rights reserved.
//

#define HC_SHORTHAND
#import <OCHamcrestIOS/OCHamcrestIOS.h>

#import <XCTest/XCTest.h>
#import "RLAsync.h"
#import "RLAsyncMethod.h"

@interface RLAsyncTests : XCTestCase

@end

@implementation RLAsyncTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

// ============================================================
// === RLAsyncMethod Tests ====================================
// ============================================================

-(void) test_RLAsyncMethod_InitializesCorrectly
{
    RLAsyncMethod* asyncMethod = [RLAsyncMethod context:self method:nil];
    assertThat(asyncMethod, notNilValue());
    assertThat(asyncMethod.context, notNilValue());
}

// ============================================================
// === RLAsync Sequence Tests =================================
// ============================================================

-(void) test_RLAsync_PerformsSequenceGood
{
    NSMutableArray* methods = @[].mutableCopy;
    for (NSInteger i = 0; i<3; i++) {
        [methods addObject:[RLAsyncMethod context:self method:@selector(sequenceGood:data:)]];
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block BOOL isComplete = NO;
    __block NSError* myError = nil;
    
    RLAsync* sequence = [RLAsync sequence:methods complete:^(id data) {
        isComplete = YES;
        dispatch_semaphore_signal(semaphore);
    } error:^(NSError *err) {
        myError = err;
        dispatch_semaphore_signal(semaphore);
    }];
    
    [sequence run];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
    
    assertThatBool(isComplete, equalToBool(YES));
    assertThat(myError, nilValue());
}

-(void) test_RLAsync_PerformsSequenceBad
{
    NSMutableArray* methods = @[].mutableCopy;
    
    RLAsyncMethod* bad = [RLAsyncMethod context:self method:@selector(sequenceBad:data:)];
    [methods addObject:bad];
    
    for (NSInteger i = 0; i<3; i++) {
        [methods addObject:[RLAsyncMethod context:self method:@selector(sequenceWithData:data:)]];
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block BOOL isComplete = NO;
    __block NSError* myError = nil;
    
    RLAsync* sequence = [RLAsync sequence:methods complete:^(id data) {
        isComplete = YES;
        dispatch_semaphore_signal(semaphore);
    } error:^(NSError *err) {
        myError = err;
        dispatch_semaphore_signal(semaphore);
    }];
    
    NSMutableArray* myArr = @[].mutableCopy;
    [sequence runWithData:myArr];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
    
    assertThatBool(isComplete, equalToBool(NO));
    assertThat(myError, notNilValue());
    assertThatInt(myArr.count, equalToInt(0));
}

-(void) test_RLAsync_PerformsSequenceWithData
{
    NSMutableArray* methods = @[].mutableCopy;
    for (NSInteger i = 0; i<3; i++) {
        [methods addObject:[RLAsyncMethod context:self method:@selector(sequenceWithData:data:)]];
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block BOOL isComplete = NO;
    __block NSError* myError = nil;
    
    RLAsync* sequence = [RLAsync sequence:methods complete:^(id data) {
        isComplete = YES;
        dispatch_semaphore_signal(semaphore);
    } error:^(NSError *err) {
        myError = err;
        dispatch_semaphore_signal(semaphore);
    }];
    
    NSMutableArray* myArr = @[].mutableCopy;
    [sequence runWithData:myArr];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
    
    assertThatBool(isComplete, equalToBool(YES));
    assertThat(myError, nilValue());
    assertThatInt(myArr.count, equalToInt(3));
}

-(void) test_RLAsync_PerformsWithConcurrent
{
    NSMutableArray* methods = @[].mutableCopy;
    for (NSInteger i = 0; i<3; i++) {
        [methods addObject:[RLAsyncMethod context:self method:@selector(sequenceConcurrent:data:)]];
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block BOOL isComplete = NO;
    __block NSError* myError = nil;
    
    RLAsync* sequence = [RLAsync sequence:methods complete:^(id data) {
        isComplete = YES;
        dispatch_semaphore_signal(semaphore);
    } error:^(NSError *err) {
        myError = err;
        dispatch_semaphore_signal(semaphore);
    }];
    
    NSMutableArray* myArr = @[].mutableCopy;
    [sequence runWithData:myArr];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
    
    assertThatBool(isComplete, equalToBool(YES));
    assertThat(myError, nilValue());
    assertThatInt(myArr.count, equalToInt(3));
}

// ============================================================
// === RLAsync Sequence Methods ===============================
// ============================================================

-(void) sequenceGood:(void(^)(NSError* err, id data)) callback data:(id)data
{
    callback(nil,nil);
}

-(void) sequenceBad:(void(^)(NSError* err, id data)) callback data:(id)data
{
    callback([NSError errorWithDomain:@"" code:0 userInfo:nil],nil);
}

-(void) sequenceConcurrent:(void(^)(NSError* err, id data)) callback data:(NSMutableArray* )arr
{
    NSOperationQueue* curQueue = [NSOperationQueue currentQueue];
    NSOperationQueue* queue = [NSOperationQueue new];
    [queue addOperationWithBlock:^{
        [arr addObject:@"append"];
        [curQueue addOperationWithBlock:^{
            callback(nil,arr);
        }];
    }];
}

-(void) sequenceWithData:(void(^)(NSError* err, id data)) callback data:(NSMutableArray* )arr
{
    [arr addObject:@"append"];
    callback(nil,arr);
}

// ============================================================
// === RLAsync Parallel Tests =================================
// ============================================================

-(void) test_RLAsync_PerformsParallel
{
    NSMutableArray* methods = @[].mutableCopy;
    for (NSInteger i = 0; i<3; i++) {
        [methods addObject:[RLAsyncMethod context:self method:@selector(parallelGood:)]];
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block BOOL isComplete = NO;
    __block NSError* myError = nil;
    
    RLAsync* parallel = [RLAsync parallel:methods complete:^ {
        isComplete = YES;
        dispatch_semaphore_signal(semaphore);
    } error:^(NSError *err) {
        myError = err;
        dispatch_semaphore_signal(semaphore);
    }];
    
    [parallel run];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
    
    assertThatBool(isComplete, equalToBool(YES));
    assertThat(myError, nilValue());
}

-(void) test_RLAsync_PerformsParallelBad
{
    NSMutableArray* methods = @[].mutableCopy;
    for (NSInteger i = 0; i<3; i++) {
        [methods addObject:[RLAsyncMethod context:self method:@selector(parallelGood:)]];
    }
    
    [methods addObject:[RLAsyncMethod context:self method:@selector(parallelBad:)]];
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    __block BOOL isComplete = NO;
    __block NSError* myError = nil;
    
    RLAsync* parallel = [RLAsync parallel:methods complete:^ {
        isComplete = YES;
        dispatch_semaphore_signal(semaphore);
    } error:^(NSError *err) {
        myError = err;
        dispatch_semaphore_signal(semaphore);
    }];
    
    [parallel run];
    
    while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:10]];
    }
    
    assertThatBool(isComplete, equalToBool(NO));
    assertThat(myError, notNilValue());
}

// ============================================================
// === RLAsync Parallel Methods ===============================
// ============================================================

- (void) parallelGood:(void(^)(NSError* err)) callback
{
    callback(nil);
}

- (void) parallelBad:(void(^)(NSError* err)) callback
{
    callback([NSError errorWithDomain:@"" code:0 userInfo:nil]);
}

@end
