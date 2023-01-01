type DocumentURI is String


class Position
    var line: LSPInteger
    var character: LSPInteger
    new ref create(line': LSPInteger, character': LSPInteger) =>
        line = line'
        character = character'


class Range
    // The spec nomenclature is "start" and "end", 
    // but we use "open" and "close" to avoid the
    // use of the reserved word "end".
    var open: Position
    var close: Position
    new ref create(open': Position, close': Position) =>
        open = open'
        close = close'


class TextDocumentItem
    var uri: DocumentURI
    var languageId: String
    var version: LSPInteger
    var text: String
    new ref create(uri': DocumentURI, languageId': String, version': LSPInteger, text': String) =>
        uri = uri'
        languageId = languageId'
        version = version'
        text = text'


class TextDocumentIdentifier
    var uri: DocumentURI
    new ref create(uri': DocumentURI) =>
        uri = uri'


class TextDocumentPositionParams
    var textDocument: TextDocumentIdentifier
    var position: Position
    new ref create(textDocument': TextDocumentIdentifier, position': Position) =>
        textDocument = textDocument'
        position = position'