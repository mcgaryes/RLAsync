RLAsync
=======

RLAsync is an asynchronous client for Objective-C, for use with iOS and MacOS development. The concept is simple. Provide an Async constructor (sequence or parallel) with a series of selectors and react to their success or fault.

###Installation

Include the RLAsync and RLAsyncMethod .m and .h files in your project somewhere.

###Usage

The library provides a fairly simple and straightforward way of writing asynchrounous code in a way that is earier to test, manage and more importantly read!

You'll need to define some methods with block callbacks before you can run them within the Async libary. If you're planning on running all the methods in parallel and just wanting to know when they're all done you'll describe your methods like so:

	-(void) myMethod:(void(^)(NSError* err)) callback; 

However if you're wanting to run your methods in sequence (one after another) you'll need to describe your methods like this:

	-(void) myMethod:(void(^)(NSError* err, id data)) callback data:(id) data; 

Notice that the only differences in the two methods are the inclusion of a data object in the callback block and a data argument on the end of the method itself. This is included so that sequence methods can pass data through to the next method in the sequence.

Because of how arrays work in Objective-C we can't simply add a bunch of selectors to an NSArray, so we'll need to wrap the methods we defined above in an RLAsyncMethod object. This way we can keep track of the methods as they run in sequence or in parallel. This is very simple to do and you'll wrap the methods like so:

	[RLAsyncMethod context:self method:@selector(myMethod:)];

The class method RLAsyncMethod takes the two arguments context and method. Where method is the selector we'll want to perform and context is the instance in which we'll perform that selector on.

Now that we have our methods wrapped we can add them to a control flow, either sequence or parallel. You'll do this by referencing one of two methods on the RLAsync class.

	[RLAsync parallel:complete:error:]

OR
	
	[RLAsync sequence:complete:error:]

There is also an option that takes a progress callback as well

	[RLAsync parallel:complete:error:progress:]

OR

	[RLAsync sequence:complete:error:progress:]

The following is a full example of both a sequence and parallel implementations:
	
	// sequence example

	-(void) runSequence
	{
		RLAsyncMethod* m1 = [RLAsyncMethod context:self method:@selector(myMethod:data:)];
		RLAsyncMethod* m2 = [RLAsyncMethod context:self method:@selector(myMethod:data:)];
	    
	    [[RLAsync sequence:@[m1,m2] complete:^(id data){
	        NSLog(@"complete with data %@",data);
	    } error:^(NSError *err) {
	        NSLog(@"%@",err);
	    }] runWithData:someMutableObject];
	}

	-(void) myMethod:(void(^)(NSError* err, id data)) callback data:(id) data
	{
		// Asynchronous code and possibly manipulate data goes here.
		// If everything goes according to plan run the callback with 
		// the error property as nil otherwise pass the error 
		// encountered in the callback
		callback(nil,data);
	}

	// parallel example

	-(void) runParallel
	{
		RLAsyncMethod* m1 = [RLAsyncMethod context:self method:@selector(myMethod:)];
		RLAsyncMethod* m2 = [RLAsyncMethod context:self method:@selector(myMethod:)];
	    
	    [[RLAsync parallel:@[m1,m2] complete:^{
	        NSLog(@"complete");
	    } error:^(NSError *err) {
	        NSLog(@"%@",err);
	    }] run];
	}

	-(void) myMethod:(void(^)(NSError* err)) callback
	{
		// Asynchronous code here. If everything goes according to plan run the
		// callback with the error property as nil otherwise pass the error 
		// encountered in the callback
		callback(nil);
	}

