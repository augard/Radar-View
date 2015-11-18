//: Playground - noun: a place where people can play

import Cocoa

var str = "Hello, playground"

var objects: [Int: [String]] = [0: ["test", "dasd", "eeeee"], 1: ["lorem", "test", "xxx", "martin"], 3: ["mirka", "lojza"]]

objects.count

var lines: [Int] = objects.map { (index: Int, object: [String]) -> Int in
    return object.count
}