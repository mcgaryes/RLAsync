//
//  RLAsync.h
//  RLAsync
//
//  Created by Eric McGary on 12/7/13.
//  Copyright (c) 2013 Eric McGary. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RLAsync : NSObject

// sequence

+ (RLAsync*) sequence:(NSArray*) methods
             complete:(void(^)(id data)) complete
                error:(void(^)(NSError* err)) error;

+ (RLAsync*) sequence:(NSArray*) methods
             complete:(void(^)(id data)) complete
                error:(void(^)(NSError* err)) error
             progress:(void(^)(NSInteger completed, NSInteger total)) progress;

// parallel

+ (RLAsync*) parallel:(NSArray*) methods
             complete:(void(^)(void)) complete
                error:(void(^)(NSError* err)) error;

+ (RLAsync*) parallel:(NSArray*) methods
             complete:(void(^)(void)) complete
                error:(void(^)(NSError* err)) error
             progress:(void(^)(NSInteger completed, NSInteger total)) progress;

- (void) run;
- (void) runWithData:(id)data;

- (void) cancel;

@end
