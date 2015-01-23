//
//  AppDelegate.m
//  MigrationLesson
//
//  Created by Aynur Galiev on 21.01.15.
//  Copyright (c) 2015 Flatstack. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    if ([self isMigrationNeeded]) {
        [self migrate:nil];
    }
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self saveContext];
}

- (NSURL *)sourceStoreURL {
    NSURL *dir = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *oldFile = [dir URLByAppendingPathComponent:@"MigrationLesson.sqlite"];
    return oldFile;
}

- (BOOL)isMigrationNeeded {
    
    NSError *error = nil;
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType
                                                                                              URL:[self sourceStoreURL]
                                                                                            error:&error];
    BOOL isMigrationNeeded = NO;
    if (sourceMetadata != nil) {
        
        NSManagedObjectModel *destinationModel = [self managedObjectModel];
        // Migration is needed if destinationModel is NOT compatible
        isMigrationNeeded = ![destinationModel isConfiguration:nil compatibleWithStoreMetadata:sourceMetadata];
    }
    
    NSLog(@"isMigrationNeeded: %@", (isMigrationNeeded == YES) ? @"YES" : @"NO");
    return isMigrationNeeded;
}


- (BOOL)migrate:(NSError *__autoreleasing *)error {
    
    NSURL *sourceUrl = [self sourceStoreURL];
    
    // - Get metadata for source store from its URL with given type.
    NSDictionary *sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:NSSQLiteStoreType URL:sourceUrl error:error];
    if (sourceMetadata == NO) {
        NSLog(@"FAILED to create source meta data");
        return NO;
    }
    
    
    // - Create model from source store meta deta,
    NSManagedObjectModel *sourceModel = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]] forStoreMetadata:sourceMetadata];
    if (sourceModel == nil) {
        NSLog(@"FAILED to create source model, something wrong with source xcdatamodel.");
        return NO;
    }
    
    
    NSManagedObjectModel *destinationModel = [self managedObjectModel];
    NSMappingModel *mappingModel = [NSMappingModel mappingModelFromBundles:@[[NSBundle mainBundle]]
                                                            forSourceModel:sourceModel
                                                          destinationModel:destinationModel];
    
    
    // - Create the destination store url
    NSString *fileName = @"MigrationLesson_V2.sqlite";
    NSURL *destinationStoreURL =  [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:fileName];
    
    
    // - Migrate from source to latest matched destination model,
    NSMigrationManager *manager = [[NSMigrationManager alloc] initWithSourceModel:sourceModel destinationModel:destinationModel];
    BOOL didMigrate = [manager migrateStoreFromURL:sourceUrl
                                              type:NSSQLiteStoreType
                                           options:nil
                                  withMappingModel:mappingModel
                                  toDestinationURL:destinationStoreURL
                                   destinationType:NSSQLiteStoreType
                                destinationOptions:nil
                                             error:error];
    if (!didMigrate) {
        return NO;
    }
    
    NSLog(@"Migrating from source: %@ ===To=== %@", sourceUrl.path, destinationStoreURL.path);
    
    // Delete old sqlite file
    NSError *err = nil;
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm removeItemAtURL:sourceUrl error:&err]) {
        NSLog(@"File delete failed.");
        return NO;
    }
    
    NSString *str1 = [NSString stringWithFormat:@"%@-shm",sourceUrl.path];
    [fm removeItemAtURL:[NSURL fileURLWithPath:str1] error:&err];
    str1 = [NSString stringWithFormat:@"%@-wal",sourceUrl.path];
    [fm removeItemAtURL:[NSURL fileURLWithPath:str1] error:&err];
    
    // Copy into new location
    if (![fm moveItemAtURL:destinationStoreURL toURL:sourceUrl error:&err]) {
        NSLog(@"File move failed.");
        return NO;
    }
    
    NSLog(@"Migration successful");

    return didMigrate;
}







- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "FS.MigrationLesson" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MigrationLesson" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MigrationLesson.sqlite"];
    NSError *error = nil;
//    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
//                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
//                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


@end
