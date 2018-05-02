/// Writer for GraphViz .dot files
///
//
//	DotWriter.swift
//

import Foundation

/// Quote an identifier, if needed.
/// According to the Dot documentation an ID is:
/// 
/// - Any string of alphabetic ([a-zA-Z\200-\377]) characters, underscores
///   ('_') or digits ([0-9]), not beginning with a digit;
/// - a numeral [-]?(.[0-9]+ | [0-9]+(.[0-9]*)? );
/// - any double-quoted string ("...") possibly containing escaped quotes
///   (\")1;
/// - an HTML string (<...>).
///
func dotQuoteID(_ string: String) -> String {
    /*
    ID is:

        - Any string of alphabetic ([a-zA-Z\200-\377]) characters, underscores
          ('_') or digits ([0-9]), not beginning with a digit;
        - a numeral [-]?(.[0-9]+ | [0-9]+(.[0-9]*)? );
        - any double-quoted string ("...") possibly containing escaped quotes
          (\")1;
        - an HTML string (<...>).
    */
    precondition(!string.isEmpty, "DOT string can't be empty")

    // Need to quote?
    var validChars = CharacterSet.alphanumerics
    validChars.insert(charactersIn:UnicodeScalar(128)...UnicodeScalar(255))
    validChars.insert(UnicodeScalar("_"))

    // FIXME: Wait for swift Collection.allSatisfy(...)
    let isRegularID = !string.unicodeScalars.contains {
        char in
        return !(validChars.contains(char) || char == "_")
    }

    // Do we need to quote?
    if isRegularID {
        return string
    }
    else {
        return string.map {
            char in char == "\"" ?  "\\\"" : String(char)
        }.joined(separator:"")
    }
}

func dotAttributeList(_ dict: [String:String]) -> String {
    let retval = dict.map {
        key, value in

        let quotedValue: String
        let quotedKeys = ["label"]

        // FIXME: This is primitive, needs to either use the quoting method
        // above or have its own way of quoting.
        if quotedKeys.contains(key) || value.contains(" ") {
            // Quote the value
            quotedValue = "\"\(value)\""
        }
        else {
            quotedValue = value
        }
        return "\(key)=\(quotedValue)"
    }.joined(separator:", ")

    return retval
}

/// Type of the graph – directed or undirected.
///
public enum GraphType {
    case undirected
    case directed

    var dotKeyword: String {
        switch self {
        case .undirected: return "graph"
        case .directed: return "digraph"
        }
    }
    var edgeOperator: String {
        switch self {
        case .undirected: return "--"
        case .directed: return "->"
        }
    }
}

/// Generator for `.dot` graph files. Every object and its links are
/// emmited in a single line.
public class DotWriter {
	public let path: String

	let file: FileHandle
    let name: String
    let type: GraphType

    var closed: Bool = false
    // TODO: Make this configurable
    let indent = "    "

	public init(path: String, name: String, type: GraphType) {
		let manager = FileManager.default

		self.path = path
        self.type = type
        self.name = name

		manager.createFile(atPath: path, contents:nil, attributes:nil)

		file = FileHandle.init(forWritingAtPath: path)!
        writeHeader()
	}

	func writeLine(_ str: String) {
        precondition(closed == false, "Writer for graph '\(name)' is closed.")

		let line = str + "\n"
		if let data = line.data(using: String.Encoding.utf8) {
			file.write(data)
		}
	}

	public func close() {
		self.writeLine("}")
        self.closed = true
	}


    func writeHeader() {
        let quotedName = dotQuoteID(name)
        writeLine("\(type.dotKeyword) \(quotedName) {")
    }

    /// Write a node statement
    public func writeNode(_ id: String, attributes: [String:String]?=nil) {
        let line: String    
        let attrString = attributes.map { "[\(dotAttributeList($0))]" } ?? ""
        
        line = "\(indent)\(id)\(attrString);"

        writeLine(line)
    }

    /// Write an edge statement
    public func writeEdge(from source:String, to target:String, attributes:
                          [String:String]?=nil) {
        let line: String
        let attrString = attributes.map { "[\(dotAttributeList($0))]" } ?? ""

		line = "\(indent)\(source) \(type.edgeOperator) \(target)\(attrString);"

        writeLine(line)
    }
}

