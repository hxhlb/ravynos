/*
 * Copyright (C) 2022-2024 Zoe Knox <zoe@pixin.net>
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#define WINDOWSERVER 1

#import <AppKit/AppKit.h>
#import <sys/event.h>
#import "desktop.h"
#import <servers/bootstrap.h>
#import <WindowServer/message.h>


@implementation AppDelegate
- (AppDelegate *)init {
    menuBar = [MenuBarWindow alloc];
    return self;
}

#if 0
            case MSG_ID_PORT:
            {
                mach_port_t port = msg.portMsg.descriptor.name;
                pid_t pid = msg.portMsg.pid;
                [menuBar setPort:port forPID:pid];
                break;
            }
                    case CODE_ADD_RECENT_ITEM:
                    {
                        NSURL *url = [NSURL URLWithString:
                            [[NSString alloc] initWithBytes:msg.msg.data
                            length:msg.msg.len encoding:NSUTF8StringEncoding]];
                        if(!url)
                            break;
                        [menuBar addRecentItem:url];
                        break;
                    }
                    case CODE_APP_BECAME_ACTIVE:
                    {
                        pid_t pid;
                        memcpy(&pid, msg.msg.data, msg.msg.len);
                        //NSLog(@"CODE_APP_BECAME_ACTIVE: pid = %d", pid);
                        if([menuBar activeProcessID] != pid)
                            [menuBar activateMenuForPID:pid];
                        break;
                    }
                    case CODE_APP_BECAME_INACTIVE:
                    {
                        pid_t pid;
                        memcpy(&pid, msg.msg.data, msg.msg.len);
                        //NSLog(@"CODE_APP_BECAME_INACTIVE: pid = %d", pid);
                        break;
                    }
                    case CODE_ACTIVATION_STATE:
                    {
                        pid_t pid;
                        memcpy(&pid, msg.msg.data, sizeof(int));
                        NSLog(@"CODE_APP_ACTIVATE: pid = %d", pid);
                        mach_port_t port = [menuBar portForPID:pid];
                        if(port != MACH_PORT_NULL) {
                            Message activate = {0};
                            activate.header.msgh_remote_port = port;
                            activate.header.msgh_bits = MACH_MSGH_BITS_SET(MACH_MSG_TYPE_COPY_SEND, 0, 0, 0);
                            activate.header.msgh_id = MSG_ID_INLINE;
                            activate.header.msgh_size = sizeof(activate) - sizeof(mach_msg_trailer_t);
                            activate.code = msg.msg.code;
                            memcpy(activate.data, msg.msg.data+sizeof(int), sizeof(int)); // window ID
                            activate.len = sizeof(int);
                            mach_msg((mach_msg_header_t *)&activate, MACH_SEND_MSG,
                                sizeof(activate) - sizeof(mach_msg_trailer_t),
                                0, MACH_PORT_NULL, 2000 /* ms timeout */, MACH_PORT_NULL);
                        }
                        break;
                    }
                    case CODE_APP_HIDE:
                    {
                        pid_t pid;
                        memcpy(&pid, msg.msg.data, sizeof(int));
                        NSLog(@"CODE_APP_HIDE: pid = %d", pid);
                        mach_port_t port = [menuBar portForPID:pid];
                        if(port != MACH_PORT_NULL) {
                            Message activate = {0};
                            activate.header.msgh_remote_port = port;
                            activate.header.msgh_bits = MACH_MSGH_BITS_SET(MACH_MSG_TYPE_COPY_SEND, 0, 0, 0);
                            activate.header.msgh_id = MSG_ID_INLINE;
                            activate.header.msgh_size = sizeof(activate) - sizeof(mach_msg_trailer_t);
                            activate.code = msg.msg.code;
                            activate.len = 0;
                            mach_msg((mach_msg_header_t *)&activate, MACH_SEND_MSG,
                                sizeof(activate) - sizeof(mach_msg_trailer_t),
                                0, MACH_PORT_NULL, 2000 /* ms timeout */, MACH_PORT_NULL);
                        }
                        break;
                    }
		    case CODE_ADD_STATUS_ITEM:
		    {
			NSData *data = [NSData
			    dataWithBytes:msg.msg.data length:msg.msg.len];
			NSObject *o = nil;
			@try {
			    o = [NSKeyedUnarchiver unarchiveObjectWithData:data];
			}
			@catch(NSException *localException) {
			    NSLog(@"%@",localException);
			}

			if(o == nil || [o isKindOfClass:[NSDictionary class]] == NO ||
			    [(NSDictionary *)o objectForKey:@"StatusItem"] == nil ||
			    [(NSDictionary *)o objectForKey:@"ProcessID"] == nil ||
			    ![[(NSDictionary *)o objectForKey:@"StatusItem"] isKindOfClass:[NSStatusItem class]]) {
			    fprintf(stderr, "archiver: bad input\n");
			    break;
			}

			NSDictionary *dict = (NSDictionary *)o;
			unsigned int pid = [[dict objectForKey:@"ProcessID"] unsignedIntValue];
		    	// watch for this PID to exit
			struct kevent kev[1];
			EV_SET(kev, pid, EVFILT_PROC, EV_ADD|EV_ONESHOT,
				NOTE_EXIT, 0, NULL);
			kevent(_kq, kev, 1, NULL, 0, NULL);

			[menuBar
			    addStatusItem:[dict objectForKey:@"StatusItem"]
			    pid:pid];
			break;
		    }
                }
                break;
        }
    }
}
#endif

// called from our kq watcher thread
// FIXME: get these as mach_msg from WS
- (void)processKernelQueue {
    struct kevent out[128];
    int count = kevent(_kq, NULL, 0, out, 128, NULL);

    for(int i = 0; i < count; ++i) {
        switch(out[i].filter) {
            case EVFILT_PROC:
                if((out[i].fflags & NOTE_EXIT)) {
                    //NSLog(@"PID %lu exited", out[i].ident);
                    //[menuBar removeMenuForPID:out[i].ident]; // FIXME: forApp
                    //[menuBar removeStatusItemsForPID:out[i].ident]; // FIXME: forApp
                }
                break;
            default:
                NSLog(@"unknown filter");
        }
    }
}

-(void)applicationWillFinishLaunching:(NSNotification *)note {
    NSScreen *mainDisplay = [[NSScreen screens] objectAtIndex:0];
    [menuBar initWithFrame:[mainDisplay visibleFrame]];
    [menuBar setDelegate:self];
    [[menuBar contentView] setNeedsDisplay:YES];
    [menuBar makeKeyAndOrderFront:self];
    [menuBar makeMainWindow];
}

/* Recursively set all menu targets and delegates to our proxy */
-(void)_menuEnumerateAndChange:(NSMenu *)menu {
    NSArray *items = [menu itemArray];
    [menu setDelegate:self];
    for(int i = 0; i < [items count]; ++i) {
        NSMenuItem *item = [items objectAtIndex:i];
        if([item isSeparatorItem] || [item isHidden] || ![item isEnabled])
            continue;
        [item setTarget:self];
        [item setAction:@selector(clicked:)];
        if([item hasSubmenu])
            [self _menuEnumerateAndChange:[item submenu]];
    }
}

- (void)menuDidUpdate:(NSNotification *)note {
    NSMutableDictionary *dict = (NSMutableDictionary *)[note userInfo];
    pid_t pid = [[dict objectForKey:@"ProcessID"] intValue];
    NSMenu *mainMenu = [dict objectForKey:@"MainMenu"];
    [self _menuEnumerateAndChange:mainMenu];
    //[menuBar setMenu:mainMenu forPID:pid]; // FIXME: forApp

    //FIXME: forApp
    //if(![menuBar activateMenuForPID:pid]) // FIXME: don't activate unless window becomes active
    //    NSLog(@"could not activate menus!");
}

// FIXME: send to WS
- (void)clicked:(NSMenuItem *)object {
    int itemID = [object tag];

    Message clicked = {0};
    clicked.header.msgh_remote_port = MACH_PORT_NULL; // FIXME: send to WS [menuBar activePort];
    clicked.header.msgh_bits = MACH_MSGH_BITS_SET(MACH_MSG_TYPE_COPY_SEND, 0, 0, 0);
    clicked.header.msgh_id = MSG_ID_INLINE;
    clicked.header.msgh_size = sizeof(clicked) - sizeof(mach_msg_trailer_t);
    clicked.code = CODE_ITEM_CLICKED;
    memcpy(clicked.data, &itemID, sizeof(itemID));
    clicked.len = sizeof(itemID);

    if(mach_msg((mach_msg_header_t *)&clicked, MACH_SEND_MSG, sizeof(clicked) - sizeof(mach_msg_trailer_t),
        0, MACH_PORT_NULL, 2000 /* ms timeout */, MACH_PORT_NULL) != MACH_MSG_SUCCESS)
        //NSLog(@"Failed to send menu click to PID %d on port %d", [menuBar activeProcessID],
        //    clicked.header.msgh_remote_port);
        NSLog(@"oops");
}

-(void)mouseDown:(NSEvent *)event {
    NSLog(@"mouse down at %@", event);
}

-(void)mouseMoved:(NSEvent *)event {
    NSLog(@"mouse moved at %@", event);
}

@end

