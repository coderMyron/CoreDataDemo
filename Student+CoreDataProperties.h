//
//  Student+CoreDataProperties.h
//  CoreDataDemo
//
//  Created by LMY on 2023/2/10.
//
//

#import "Student+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface Student (CoreDataProperties)

+ (NSFetchRequest<Student *> *)fetchRequest NS_SWIFT_NAME(fetchRequest());

@property (nullable, nonatomic, copy) NSString *name;
@property (nonatomic) int16_t age;
@property (nonatomic) int32_t score;

@end

NS_ASSUME_NONNULL_END
