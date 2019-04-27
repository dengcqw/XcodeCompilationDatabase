import XCTest
import XcodeCompilationDatabaseCore

public extension String {
    func getFileNameWithoutType() -> String? {
        guard let slashIndex = lastIndex(of: "/") else { return nil }
        let fileName = suffix(from: self.index(after: slashIndex))
        if let ret = fileName.split(separator: ".").first {
            return String(ret)
        } else {
            return nil
        }
    }
    
    mutating func replaceCommandLineParam(withPrefix prefix: String, replaceString: String) {
        guard let range = self.range(of: prefix) else { return }
        var preChar: Character = Character.init("")
        var distance: Int = 0
        for (index, char) in self.suffix(from: range.upperBound).enumerated() {
            if char == "-" && preChar == " " {
                distance = index
                break
            } else {
                preChar = char
            }
        }
        guard distance != 0 else { return }
        let upperBound = self.index(range.upperBound, offsetBy: distance)
        self.replaceSubrange(range.lowerBound..<upperBound, with: replaceString)
    }
    
    func hasBlankPrefix(count: Int) -> Bool {
        var _count = 0
        for char in self {
            if char != " " {
                break
            }
            _count = _count + 1
        }
        return count == _count
    }
    
    func rangeOfOptionContent(option: String, reverse: Bool) -> Range<String.Index>? {
        if reverse {
            var idx = endIndex
            while(idx != startIndex) {
                var blankIdx = idx
                repeat {
                    if blankIdx == startIndex { break }
                    blankIdx = index(blankIdx, offsetBy: -1)
                } while(self[blankIdx] != " ")
                if index(blankIdx, offsetBy: -option.count) >= startIndex &&
                    option == self[index(blankIdx, offsetBy: -option.count)..<blankIdx] {
                    return index(blankIdx, offsetBy: 1) ..< idx
                } else {
                    idx = blankIdx // not need -1, is open upper bound
                }
            }
        } else {
            var idx = startIndex
            while(idx != endIndex) {
                var blankIdx = idx
                repeat { // find blank
                    blankIdx = index(blankIdx, offsetBy: 1)
                    if blankIdx == endIndex { break }
                } while(self[blankIdx] != " ")
                
                if distance(from: idx, to: blankIdx) == option.count && self[idx..<blankIdx] == option {
                    idx = index(blankIdx, offsetBy: 1) // content start index
                    repeat {  // find next blank
                        blankIdx = index(blankIdx, offsetBy: 1)
                        if blankIdx == endIndex { break }
                    } while(self[blankIdx] != " ")
                    return idx..<blankIdx
                } else {
                    idx = index(blankIdx, offsetBy: 1)
                }
            }
        }
        return nil
    }
}


class LogParsingTests: XCTestCase {
    
    func testClangLogParse() {
        let test = "gcc -o 11111111 -c 2222222  -2-2 -23-234"
        let range = test.rangeOfOptionContent(option: "-c", reverse: true)
        assert(range != nil)
        assert(test[range!] == "2222222")
    }
}
