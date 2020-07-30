import UIKit


//dispatchBarrier
class ThreadSafeArray {
    let isolation = DispatchQueue(label: "com.fikrihelmi.dispatchbarrier", attributes: .concurrent)
    
    private var _array: [Int] = []
    
    var array: [Int] {
        get {
            return isolation.sync{
                _array
            }
        }
        
        set {
            isolation.async(flags: .barrier) {
                self._array = newValue
            }
        }
    }
}

//DispatchWorkItem
var value = 5
let workItem = DispatchWorkItem{
    value += 5
}

workItem.perform()

let queue = DispatchQueue(label: "com.fikrihelmi.dispatchworkitem", qos: .utility)
queue.async(execute: workItem)

workItem.notify(queue: DispatchQueue.main){
    print("Final Value: \(value)")
}


//dispatchGroup
func task1(dispatchGroup: DispatchGroup) {
    let queue = DispatchQueue(label: "com.fikrihelmi.dispatchGroup.task1")
    
    queue.async {
        sleep(1)
        print("Task 1 executed")
        dispatchGroup.leave()
    }
}

func task2(dispatchGroup: DispatchGroup) {
    DispatchQueue.global().async {
        sleep(2)
        print("Task 2 executed")
        dispatchGroup.leave()
    }
}
 
func task3(dispatchGroup: DispatchGroup) {
    DispatchQueue.main.async {
        print("Task 3 executed")
        dispatchGroup.leave()
    }
}

let dispatchGroup = DispatchGroup()

dispatchGroup.enter()
task1(dispatchGroup: dispatchGroup)
dispatchGroup.enter()
task2(dispatchGroup: dispatchGroup)
dispatchGroup.enter()
task3(dispatchGroup: dispatchGroup)

dispatchGroup.notify(queue: DispatchQueue.main){
    print("All task finished")
}
//DispatchGroup.enter() dan DispatchGroup.leave() harus berjumlah sama

//Completion Block
func expensiveTask(data: String, completion: @escaping (String) -> Void) {
    let queue = DispatchQueue(label: "com.fikrihelmi.completionblock")
    
    queue.async {
        print("Processing: \(data)")
        sleep(2) // imitate expensive task
        completion("Processing \(data) finished")
    }
}

let mainQueue = DispatchQueue(label: "com.fikrihelmi.main", qos: .userInteractive)
mainQueue.async {
    expensiveTask(data: "Get User") {
        result in
        print(result)
    }
    
    print("Main Queue Run")
}

//Delegation

protocol TaskDelegate {
    func taskFinished(result: String)
}

struct Task {
    var delegate: TaskDelegate?
    
    func expensiveTask(data: String) {
        let queue = DispatchQueue(label: "com.dicoding.delegation")
        
        queue.async {
            print("Processing: \(data)")
            sleep(2)
            self.delegate?.taskFinished(result: "Processing \(data) finished")
        }
        
    }
}

struct Main: TaskDelegate {
    func run() {
        let mainQueue = DispatchQueue(label: "com.dicoding.main", qos: .userInteractive)
        
        mainQueue.async {
            var task = Task()
            task.delegate = self
            task.expensiveTask(data: "Get User")
            print("Main Queue Run")
        }
    }
    
    func taskFinished(result: String) {
        print(result)
    }
}

let main = Main()
main.run()

//block operation dan operation queue
enum Color: String {
   case red = "red"
   case blue = "blue"
}
 
let count = 5
 
func show(color: Color, count: Int) {
   for _ in 1...count {
       print(color.rawValue)
   }
}

let queueOP = OperationQueue()
queueOP.maxConcurrentOperationCount = 2

let operation1 = BlockOperation(block: {
    show(color: .red, count: count)
})

operation1.qualityOfService = .userInteractive

let operation2 = BlockOperation(block: {
    show(color: .blue, count: count)
})

operation1.completionBlock = {
    print("Operation 1 completed")
}

operation2.completionBlock = {
    print("Operation 2 completed")
}

operation2.addDependency(operation1)

queueOP.addOperation(operation1)
queueOP.addOperation(operation2)


