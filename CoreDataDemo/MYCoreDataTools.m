//
//  CoreDataTools.m
//  CoreDataDemo
//
//  Created by LMY on 2023/2/10.
//

#import "MYCoreDataTools.h"
#import "Student+CoreDataClass.h"
#import "NSManagedObjectContext+GenerateContext.h"
#import "AppDelegate.h"

@interface MYCoreDataTools()

@property (nonatomic, strong) NSManagedObjectContext *mainContext;

@end

static MYCoreDataTools *instance;

@implementation MYCoreDataTools

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MYCoreDataTools alloc] init];
    });
    return instance;
}

- (NSManagedObjectContext *)mainContext {
    if(_mainContext == nil){
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        _mainContext = appDelegate.mainContext;
    }
    return _mainContext;
}

-(void)saveContext {
    AppDelegate *appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [appDelegate saveContextWithWait:NO];
}

- (void)insertData:(void(^)(BOOL success, NSError *error))result {
    NSManagedObjectContext *context = [NSManagedObjectContext generatePrivateContextWithParent:self.mainContext];
    [context performBlock:^{
        // 1.根据Entity名称和NSManagedObjectContext获取一个新的继承于NSManagedObject的子类Student
        Student * student = [NSEntityDescription  insertNewObjectForEntityForName:@"Student"  inManagedObjectContext:context];
        
        //2.根据表Student中的键值，给NSManagedObject对象赋值
        student.name = [NSString stringWithFormat:@"Mr-%d",arc4random()%100];
        student.age = arc4random()%20;
        student.score = arc4random()%100;
        
        //   3.保存插入的数据
        NSError *error = nil;
        if ([context save:&error]) {
            [self.mainContext performBlock:^{
                [self saveContext];
                result(YES, nil);
            }];
            NSLog(@"数据插入到数据库成功");
        }else{
            NSLog(@"数据插入到数据库失败, %@",error);
            [self.mainContext performBlock:^{
                result(NO, error);
            }];
        }
    }];
    
}

- (void)searchData:(void(^)(NSArray *array))result {
    NSManagedObjectContext *context = [NSManagedObjectContext generatePrivateContextWithParent:self.mainContext];
    [context performBlock:^{
        //创建查询请求
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Student"];
        //查询条件
        NSPredicate *pre = [NSPredicate predicateWithFormat:@"score > %@", @0];
        request.predicate = pre;
        
        // 从第几页开始显示
        // 通过这个属性实现分页
        //request.fetchOffset = 0;
        // 每页显示多少条数据
        //request.fetchLimit = 6;
        
        //发送查询请求
        NSArray *resArray = [context executeFetchRequest:request error:nil];
        NSLog(@"%ld",resArray.count);
        NSMutableArray *arrayID = [NSMutableArray array];
        [resArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            Student *student = obj;
            [arrayID addObject:student.objectID];
        }];
        [self.mainContext performBlock:^{
//            [self saveContext];
            //跨NsManageObjectContext只能传objectID,在另一个NsManageObjectContext才能拿到NsManageObject
            NSMutableArray *resultArray = [NSMutableArray array];
            [arrayID enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSManagedObjectID *objectID = obj;
                [resultArray addObject:[self.mainContext objectWithID:objectID]];
                
            }];
            result(resultArray);
        }];
        
    }];
}

- (void)updateData:(void (^)(BOOL , NSError * ))result withScore:(int)score{
    NSManagedObjectContext *context = [NSManagedObjectContext generatePrivateContextWithParent:self.mainContext];
    [context performBlock:^{
        //创建查询请求
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Student"];
        NSPredicate *pre = [NSPredicate predicateWithFormat:@"score = %d", score];
        request.predicate = pre;
        
        //发送请求
        NSArray *resArray = [context executeFetchRequest:request error:nil];
        
        //修改
        for (Student *stu in resArray) {
            stu.name = @"全世界_iOS";
        }
        
        //保存
        NSError *error = nil;
        if ([context save:&error]) {
            NSLog(@"更新成功");
            [self.mainContext performBlock:^{
                [self saveContext];
                result(YES, nil);
            }];
        }else{
            NSLog(@"更新数据失败, %@", error);
            [self.mainContext performBlock:^{
                result(NO, error);
            }];
        }
    }];
    
}

- (void)deleteData:(void (^)(BOOL, NSError *))result withAge:(int)age {
    NSManagedObjectContext *context = [NSManagedObjectContext generatePrivateContextWithParent:self.mainContext];
    [context performBlock:^{
        //创建删除请求
        NSFetchRequest *deleRequest = [NSFetchRequest fetchRequestWithEntityName:@"Student"];
        
        //删除条件
        NSPredicate *pre = [NSPredicate predicateWithFormat:@"age < %d", age];
        deleRequest.predicate = pre;
        
        //返回需要删除的对象数组
        NSArray *deleArray = [context executeFetchRequest:deleRequest error:nil];
        
        //从数据库中删除
        for (Student *stu in deleArray) {
            [context deleteObject:stu];
        }
        
        //保存
        NSError *error = nil;
        if ([context save:&error]) {
            NSLog(@"删除 age < %d 的数据", age);
            [self.mainContext performBlock:^{
                [self saveContext];
                result(YES, nil);
            }];
        }else{
            NSLog(@"删除数据失败, %@", error);
            [self.mainContext performBlock:^{
                result(NO, error);
            }];
        }
    }];
    
}

@end
