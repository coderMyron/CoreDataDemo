//
//  Student+CoreDataProperties.m
//  CoreDataDemo
//
//  Created by LMY on 2023/2/10.
//
//

#import "Student+CoreDataProperties.h"

@implementation Student (CoreDataProperties)

+ (NSFetchRequest<Student *> *)fetchRequest {
	return [NSFetchRequest fetchRequestWithEntityName:@"Student"];
}

@dynamic name;
@dynamic age;
@dynamic score;

@end
