//
//  CoreDataTools.h
//  CoreDataDemo
//
//  Created by LMY on 2023/2/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MYCoreDataTools : NSObject

+(instancetype)shareInstance;

-(void)insertData:(void(^)(BOOL success, NSError *error))result;
-(void)searchData:(void(^)(NSArray *array))result;
-(void)updateData:(void(^)(BOOL success, NSError *error))result withScore:(int)score;
-(void)deleteData:(void(^)(BOOL success, NSError *error))result withAge:(int)age;

@end

NS_ASSUME_NONNULL_END
