//
//  ExtendNSLogFunctionality.h
//  PhotoBrowserDemo
//
//  Created by Eduardo Callado on 8/22/13.
//
//

#import <Foundation/Foundation.h>

#define NSLog(args...) ExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);

//#ifdef DEBUG
//#define NSLog(args...) ExtendNSLog(__FILE__,__LINE__,__PRETTY_FUNCTION__,args);
//#else
//#define NSLog(x...)
//#endif

void ExtendNSLog(const char *file, int lineNumber, const char *functionName, NSString *format, ...);
