//
//  IDMPhotoBrowserConstants.h
//  PhotoBrowserDemo
//
//  Created by Eduardo Callado on 10/7/13.
//
//

#define PADDING                 10
#define PAGE_INDEX_TAG_OFFSET   1000
#define PAGE_INDEX(page)        ([(page) tag] - PAGE_INDEX_TAG_OFFSET)

// Debug Logging
#if 0 // Set to 1 to enable debug logging
  #define IDMLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
  #define IDMLog(x, ...)
#endif
