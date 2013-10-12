//
//  PVAppDelegate.h
//  povemdct-client
//
//  Created by Roman Filippov on 11.10.13.
//  Copyright (c) 2013 Roman Filippov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
