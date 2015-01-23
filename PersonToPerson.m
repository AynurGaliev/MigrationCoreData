//
//  PersonToPerson.m
//  MigrationLesson
//
//  Created by Aynur Galiev on 21.01.15.
//  Copyright (c) 2015 Flatstack. All rights reserved.
//

#import "PersonToPerson.h"

@implementation PersonToPerson

- (BOOL)createDestinationInstancesForSourceInstance:(NSManagedObject *)sInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError **)error {
    
    NSManagedObjectContext *moc     = [manager destinationContext];
    NSString               *destinationEntityName = [mapping destinationEntityName];
    
    NSString *sourceSex = [sInstance valueForKey:@"sex"];
    NSString *sourceName = [sInstance valueForKey:@"name"];
    NSString *sourceSurname = [sInstance valueForKey:@"surname"];
    NSString *sourcePatronymic = [sInstance valueForKey:@"patronymic"];
    
    NSNumber* number = @0;
    if ([sourceSex isEqualToString:@"MALE"]) {
        number =  @1;
    }
    if ([sourceSex isEqualToString:@"FEMALE"]) {
        number =  @2;
    }
    
    NSManagedObject *destinationEntity = [NSEntityDescription insertNewObjectForEntityForName:destinationEntityName
                                                                            inManagedObjectContext:moc];
    [destinationEntity setValue:number forKey:@"sex"];
    [destinationEntity setValue:sourceName forKey:@"name"];
    [destinationEntity setValue:sourceSurname forKey:@"surname"];
    [destinationEntity setValue:sourcePatronymic forKey:@"patronymic"];
    
    [manager associateSourceInstance:sInstance withDestinationInstance:destinationEntity forEntityMapping:mapping];
    
    return YES;
}


//- (BOOL) createRelationshipsForDestinationInstance:(NSManagedObject *)dInstance entityMapping:(NSEntityMapping *)mapping manager:(NSMigrationManager *)manager error:(NSError *__autoreleasing *)error {
//    return YES;
//}

@end
