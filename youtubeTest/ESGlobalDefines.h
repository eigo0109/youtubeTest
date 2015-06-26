//
//  ESGlobalDefine.h
//  ezvizsports
//
//  Created by qiandong on 15/5/13.
//  Copyright (c) 2015年 hikvision. All rights reserved.
//

//Push
#define ES_PUSH_DEVICE_TOKEN @"ES_PUSH_DEVICE_TOKEN"

typedef enum
{
    PUSH_JUMP_NONE = -1,
    PUSH_JUMP_LIKE,
    PUSH_JUMP_COMMENT,
    PUSH_JUMP_NOTIFICATION,
    PUSH_JUMP_MAX
} PushJumpType;

//Server
#define ES_VIDEO_COVER_SIZE_IN_LIST_SMALL (@"@320w_180h_80Q")

#define LIVE_CATEGORY_URL @"/square/mobile/s1Live.jsp"

//Notification
#define VIDEO_COUNT_CHANGED_NOTIFICATION @"VIDEO_COUNT_CHANGED_NOTIFICATION"
#define USER_FELLOW_CHANGED_NOTIFICATION @"USER_FELLOW_CHANGED_NOTIFICATION"
#define DEFAULT_KEY @"DEFAULT_KEY"


//user defaults
#define ES_LOGIN_SUCCEEDED_TIME @"ES_LOGIN_SUCCEEDED_TIME"

#define HOME_UPDATION_DATE_KEY @"HOME_UPDATION_DATE_KEY"

#define HOME_FOLLOWED_UPDATION_DATE_KEY @"HOME_FOLLOWED_UPDATION_DATE_KEY"


//
#define ES_DECLARE_WEAK_SELF_AS(name) __weak __typeof(self) (name) = self

#define UI_NAVIGATION_BAR_HEIGHT        44
#define UI_TOOL_BAR_HEIGHT              44
#define UI_TAB_BAR_HEIGHT               49
#define UI_STATUS_BAR_HEIGHT            20
#define UI_SCREEN_WIDTH                 ([[UIScreen mainScreen] bounds].size.width)
#define UI_SCREEN_HEIGHT                ([[UIScreen mainScreen] bounds].size.height)