//
//  CurrentLotteryIssueCountDownObserver.m
//  ruyicai
//
//  Created by 熊猫 on 13-5-11.
//
//

#import "CurrentLotteryIssueCountDownManager.h"

#import "GlobalDataCacheForMemorySingleton.h"
#import "CurrentIssueCountDown.h"
#import "LotteryDictionary.h"
#import "IssueQueryNetRequestBean.h"
#import "LotteryIssueInfo.h"
 
#import "RNTimer.h"










@interface CurrentLotteryIssueCountDownManager ()
// 倒计时 Timer
@property (nonatomic, strong) RNTimer *timerForCountDown;

// 保存哪些需要倒计时观察的 彩票
@property (nonatomic, readwrite, strong) NSMutableDictionary *currentIssueCountDownBeanList;
@end









@implementation CurrentLotteryIssueCountDownManager

//
typedef NS_ENUM(NSInteger, NetRequestTagEnum) {
  // 2.2.80	当前期号查询
  kNetRequestTagEnum_Issue
};

 
 

#pragma mark -
#pragma mark 单例方法群

// 使用 Grand Central Dispatch (GCD) 来实现单例, 这样编写方便, 速度快, 而且线程安全.
-(id)init {
  // 禁止调用 -init 或 +new
  RNAssert(NO, @"Cannot create instance of Singleton");
  
  // 在这里, 你可以返回nil 或 [self initSingleton], 由你来决定是返回 nil还是返回 [self initSingleton]
  return nil;
}

// 真正的(私有)init方法
-(id)initSingleton {
  self = [super init];
  if ((self = [super init])) {
    // 初始化代码
    
		// 
		self.currentIssueCountDownBeanList = [[NSMutableDictionary alloc] initWithCapacity:20];
		
		// 缓存 "被观察者" 对象
		NSArray *lotteryDictionaryList = [GlobalDataCacheForMemorySingleton sharedInstance].lotteryDictionaryList;
		for (LotteryDictionary *lotteryDictionary in lotteryDictionaryList) {
			
			// 彩种 如果有固定信息的话, 证明是那种没有当前期号的彩票, 也就不需要倒计时
			if ([NSString isEmpty:lotteryDictionary.fixedInformation]) {
				CurrentIssueCountDown *currentIssueCountDown = [CurrentIssueCountDown currentIssueCountDownWithLotteryDictionary:lotteryDictionary];
				[self.currentIssueCountDownBeanList setValue:currentIssueCountDown forKey:lotteryDictionary.key];
			}
		}
  }
  
  return self;
}

+ (CurrentLotteryIssueCountDownManager *) sharedInstance  {
	
  static CurrentLotteryIssueCountDownManager *singletonInstance = nil;
  static dispatch_once_t pred;
  dispatch_once(&pred, ^{singletonInstance = [[self alloc] initSingleton];});
  return singletonInstance;
}

-(void)startCountDownObserver {
	if (nil == self.timerForCountDown) {
		/*
		
		 使用这种方式 注册一个 NSTimer, 当滚动 UITableView时, 将得不到事件响应
		self.timerForCountDown = [NSTimer scheduledTimerWithTimeInterval:1.0f
																															target:self
                                                            selector:@selector(timerFireMethod:)
																														userInfo:nil
																														 repeats:YES];
		 */
		/*
		 关于 滚动UITableView时, NSTimer不响应的问题说明
		 
		 当我们调用scheduledTimerWithTimeInterval方法，会创建一个NSTimer对象，把它交给当前runloop以默认mode来调度。
		 
		 相当于执行如下代码：
		 
		 [cpp] view plaincopy
		 [currentRunLoop addTimer:timer forMode:defaultMode];
		 
		 我们可以想到，runloop中维护了一张map，以mode为key，以某种结构为value，不妨命名为NSRunLoopState。
		 这个NSRunLoopState结构中，需要维护input sources集合以及NSTimer等事件源。
		 
		 
		 
		 而当我们滚动UITableView/UIScrollView，或者做一些其它UI动作时，当前runloop的mode会切换到UITrackingRunLoopMode，这是由日志输出得到的：
		 
		 [cpp] view plaincopy
		 - (void)scrollViewDidScroll:(UIScrollView *)scrollView {
		 NSLog(@"Current RunLoop Mode is %@\n", [[NSRunLoop currentRunLoop] currentMode]);
		 }
		 
		 这就相当于执行如下代码：
		 [cpp] view plaincopy
		 [currentRunLoop runMode:UITrackingRunLoopMode beforeDate:date];
		 
		 这个时候，我们需要根据UITrackingRunLoopMode来获取相应的NSRunLoopState结构，并对结构中维护的事件源进行处理。
		 所以，添加到defaultMode的NSTimer在发生UI滚动时，不会得到处理。
		 
		 
		 
		 
		 */
    /*
		NSRunLoop *runloop = [NSRunLoop currentRunLoop];
		self.timerForCountDown = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
		[runloop addTimer:self.timerForCountDown forMode:NSRunLoopCommonModes];
		[runloop addTimer:self.timerForCountDown forMode:UITrackingRunLoopMode];
     */
    
    // 这里使用了 RNTimer 这个开源代码
    /*
     RNTimer
     Simple GCD-based timer based on NSTimer. 
     It starts immediately and stops when released. 
     This avoids many of the typical problems with NSTimer:
     基于GCD实现的一个计时器, 它会立刻运行, 并在释放后立刻停止. 这就避免了很多NSTimer的典型问题:
     
     1) RNTimer runs in all modes (unlike NSTimer)
     RNTimer运行在全部的模式中(不像NSTimer)
     2) RNTimer runs when there is no runloop (unlike NSTimer)
     RNTimer运行在没有 runloop的环境中(不像NSTimer)
     3) Repeating RNTimers can easily avoid retain loops (unlike NSTimer)
     RNTimer可以很容易避免 循环引用 问题(不像NSTimer)
     4) Currently there is only a simple repeating timer (since this is the most common use that's hard to do correctly with NSTimer). It always runs on the main queue.
     当前只有一个简单的重复定时器(NSTimer很难做到这点), 它总是运行在主队列中.
     */
    __weak id weakSelf = self;
    self.timerForCountDown = [RNTimer repeatingTimerWithTimeInterval:1
                                                               block:^{
                                                                 [weakSelf timerFireMethod];
                                                               }];
    /*
     RNTimer实现了简单的GCD定时器, 能防止循环保留(只要块没有捕获self),而且在销毁时会自动把定时器设置为无效.
     它用 dispatch_source_create创建一个定时器分派源并绑定到主分派队列上,这意味着定时器总在主线程上触发.
     当然,如果愿意的话可以使用其他队列,然而它设置定时器和事件处理程序,调用 dispatch_resume打开定时器.
     分派源通常需要配置,所以它们创建时处于暂停状态,只有重新开始之后才会开始发送事件.
     */
	}
}

-(void)stopCountDownObserver {
	[self.timerForCountDown invalidate];
	self.timerForCountDown = nil;
}

-(void)resetObserver {
	[self stopCountDownObserver];
	
	NSArray *lotteryList = [self.currentIssueCountDownBeanList allValues];
	for (CurrentIssueCountDown *currentIssueCountDown in lotteryList) {
		[[DomainBeanNetworkEngineSingleton sharedInstance] cancelNetRequestByRequestIndex:currentIssueCountDown.netRequestIndex];
		[currentIssueCountDown resetCurrentIssueCountDown];
	}
	
	[self startCountDownObserver];
}

- (void)handleCurrentIssueCountDown:(CurrentIssueCountDown *)currentIssueCountDown {
	
	// 是否需要重新发起期号查询
	BOOL isNeedRequestIssueQuery = NO;
	
	do {
		
		//
		if (currentIssueCountDown.netRequestIndex != NETWORK_REQUEST_ID_OF_IDLE) {
			// 已经在请求网络
			break;
		}
		
		// 网络出现错误时, 重新发起网络请求的倒计时
		if (currentIssueCountDown.isNetworkDisconnected) {
			currentIssueCountDown.countDownSecondOfRerequestNetwork -= 1;
			
			if (currentIssueCountDown.countDownSecondOfRerequestNetwork > 0) {
				break;
			} else {
				isNeedRequestIssueQuery = YES;
				[currentIssueCountDown resetCountDownOfNetworkDisconnected];
				break;
			}
		}
		
		// 正常倒计时
		currentIssueCountDown.countDownSecond -= 1;
		if (currentIssueCountDown.countDownSecond <= 0) {
			isNeedRequestIssueQuery = YES;
		}
		
	} while (NO);
	
	if (isNeedRequestIssueQuery) {
		// 发起 当前彩票 最新期号查询
		currentIssueCountDown.netRequestIndex = [self requestIssueQueryWithLotteryCode:currentIssueCountDown.lotteryDictionary.code];
	}
}

// - (void)timerFireMethod:(NSTimer*)theTimer 这是原始NSTimer的回调方法
- (void)timerFireMethod {// 这是使用RNTimer的回调方法

	NSArray *lotteryList = [self.currentIssueCountDownBeanList allValues];
	for (CurrentIssueCountDown *currentIssueCountDown in lotteryList) {
		
		[self handleCurrentIssueCountDown:currentIssueCountDown];
	}
}

-(CurrentIssueCountDown *)queryCurrentIssueCountDownByNetRequestIndex:(NSInteger)netRequestIndex {
	RNAssert(netRequestIndex != NETWORK_REQUEST_ID_OF_IDLE, @"入参 netRequestIndex 无效");
	
	NSArray *lotteryList = [self.currentIssueCountDownBeanList allValues];
	for (CurrentIssueCountDown *currentIssueCountDown in lotteryList) {
		if (currentIssueCountDown.netRequestIndex == netRequestIndex) {
			return currentIssueCountDown;
		}
	}
	
	return nil;
}

#pragma mark -
#pragma mark 实现 IDomainNetRespondCallback 接口

- (NSInteger) requestIssueQueryWithLotteryCode:(NSString *)lotteryCode {
  // 2.4 推荐城市
  IssueQueryNetRequestBean *netRequestBean = [IssueQueryNetRequestBean issueQueryNetRequestBeanWithLotteryCode:lotteryCode];
  NSInteger netRequestIndex
  = [[DomainBeanNetworkEngineSingleton sharedInstance] requestDomainProtocolWithRequestDomainBean:netRequestBean requestEvent:kNetRequestTagEnum_Issue successedBlock:^(NSUInteger requestEvent, NSInteger netRequestIndex, id respondDomainBean) {
		CurrentIssueCountDown *currentIssueCountDown = [self queryCurrentIssueCountDownByNetRequestIndex:netRequestIndex];
		currentIssueCountDown.netRequestIndex = NETWORK_REQUEST_ID_OF_IDLE;
		
		//
		LotteryIssueInfo *lotteryIssueInfo = (LotteryIssueInfo *)respondDomainBean;
		currentIssueCountDown.lotteryIssueInfo = lotteryIssueInfo;
	} failedBlock:^(NSUInteger requestEvent, NSInteger netRequestIndex, NetRequestErrorBean *error) {
		
		// 网络请求发生错误
		CurrentIssueCountDown *currentIssueCountDown = [self queryCurrentIssueCountDownByNetRequestIndex:netRequestIndex];
		currentIssueCountDown.netRequestIndex = NETWORK_REQUEST_ID_OF_IDLE;
		currentIssueCountDown.isNetworkDisconnected = YES;
	}];
  
  return netRequestIndex;
}
  
@end