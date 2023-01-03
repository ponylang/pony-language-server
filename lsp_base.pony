use "immutable-json"

type ReceivingMode is (ReceivingModeHeader | ReceivingModeContent)
primitive ReceivingModeHeader
primitive ReceivingModeContent


class Header
  var key: String
  var value: String
  new create(key': String, value': String) =>
    key = key'
    value = value'


class Message
  let id: (I64 | String)
  let method: String
  let params: (None | JsonObject)
  new val create(id': (I64 | String), method': String, params': (None | JsonObject)) =>
    id = id'
    method = method'
    params = params'
  fun string(): String => 
    let r = id.string() + " " + method
    match params
    | let p: JsonObject => r + "\n" + p.string()
    else
      r
    end


class BaseProtocol
  var line_buffer: String ref = String
  var content_buffer: String ref = String
  var headers: Array[Header] = Array[Header]
  var receiving_mode: ReceivingMode = ReceivingModeHeader
  var debug: Debugger

  new ref create(debug': Debugger) => 
    debug = debug'

  fun ref apply(data: String): (None | Message val) =>
    match receiving_mode
    | ReceivingModeHeader => receive_headers(data)
    | ReceivingModeContent => receive_content(data)
    end

  fun ref receive_headers(data: String): (None | Message val) =>
    line_buffer.append(data)
    if line_buffer.contains("\r\n") then
      let abuffer = line_buffer.split("\r\n")
      try
        let msg = abuffer.shift()?
        line_buffer = "\r\n".join((consume abuffer).values())
        if msg == "" then
          receiving_mode = ReceivingModeContent
          content_buffer = line_buffer = String
          receive_content("")
        else
          let hdata = msg.split(": ")
          try headers.push(Header(hdata(0)?, hdata(1)?)) end
        end
      end
    end

  fun ref receive_content(data: String): (None | Message val) =>
    content_buffer.append(data)
    parse_message()

  fun ref parse_message(): (None | Message val) =>
    let doc = JsonDoc
    let data = content_buffer.clone()
    try
      doc.parse(consume data)?
      let json: JsonObject  = doc.data as JsonObject
      var id: (String | I64) = ""
      match json.data("id")?
      | let id': String => id = id'
      | let id': I64 => id = id'
      end
      var method = json.data("method")? as String
      var params = json.data("params")? as JsonObject
      Message(id, method, params)
    end


/*
{
    "jsonrpc": "2.0",
    "id": 0,
    "method": "initialize",
    "params": {
        "processId": 91090,
        "clientInfo": {
            "name": "Visual Studio Code",
            "version": "1.74.2"
        },
        "locale": "en-gb",
        "rootPath": "/Users/jairocaro-accinoviciana/pony-example",
        "rootUri": "file:///Users/jairocaro-accinoviciana/pony-example",
        "capabilities": {
            "workspace": {
                "applyEdit": true,
                "workspaceEdit": {
                    "documentChanges": true,
                    "resourceOperations": [
                        "create",
                        "rename",
                        "delete"
                    ],
                    "failureHandling": "textOnlyTransactional",
                    "normalizesLineEndings": true,
                    "changeAnnotationSupport": {
                        "groupsOnLabel": true
                    }
                },
                "configuration": true,
                "didChangeWatchedFiles": {
                    "dynamicRegistration": true,
                    "relativePatternSupport": true
                },
                "symbol": {
                    "dynamicRegistration": true,
                    "symbolKind": {
                        "valueSet": [
                            1,
                            2,
                            3,
                            4,
                            5,
                            6,
                            7,
                            8,
                            9,
                            10,
                            11,
                            12,
                            13,
                            14,
                            15,
                            16,
                            17,
                            18,
                            19,
                            20,
                            21,
                            22,
                            23,
                            24,
                            25,
                            26
                        ]
                    },
                    "tagSupport": {
                        "valueSet": [
                            1
                        ]
                    },
                    "resolveSupport": {
                        "properties": [
                            "location.range"
                        ]
                    }
                },
                "codeLens": {
                    "refreshSupport": true
                },
                "executeCommand": {
                    "dynamicRegistration": true
                },
                "didChangeConfiguration": {
                    "dynamicRegistration": true
                },
                "workspaceFolders": true,
                "semanticTokens": {
                    "refreshSupport": true
                },
                "fileOperations": {
                    "dynamicRegistration": true,
                    "didCreate": true,
                    "didRename": true,
                    "didDelete": true,
                    "willCreate": true,
                    "willRename": true,
                    "willDelete": true
                },
                "inlineValue": {
                    "refreshSupport": true
                },
                "inlayHint": {
                    "refreshSupport": true
                },
                "diagnostics": {
                    "refreshSupport": true
                }
            },
            "textDocument": {
                "publishDiagnostics": {
                    "relatedInformation": true,
                    "versionSupport": false,
                    "tagSupport": {
                        "valueSet": [
                            1,
                            2
                        ]
                    },
                    "codeDescriptionSupport": true,
                    "dataSupport": true
                },
                "synchronization": {
                    "dynamicRegistration": true,
                    "willSave": true,
                    "willSaveWaitUntil": true,
                    "didSave": true
                },
                "completion": {
                    "dynamicRegistration": true,
                    "contextSupport": true,
                    "completionItem": {
                        "snippetSupport": true,
                        "commitCharactersSupport": true,
                        "documentationFormat": [
                            "markdown",
                            "plaintext"
                        ],
                        "deprecatedSupport": true,
                        "preselectSupport": true,
                        "tagSupport": {
                            "valueSet": [
                                1
                            ]
                        },
                        "insertReplaceSupport": true,
                        "resolveSupport": {
                            "properties": [
                                "documentation",
                                "detail",
                                "additionalTextEdits"
                            ]
                        },
                        "insertTextModeSupport": {
                            "valueSet": [
                                1,
                                2
                            ]
                        },
                        "labelDetailsSupport": true
                    },
                    "insertTextMode": 2,
                    "completionItemKind": {
                        "valueSet": [
                            1,
                            2,
                            3,
                            4,
                            5,
                            6,
                            7,
                            8,
                            9,
                            10,
                            11,
                            12,
                            13,
                            14,
                            15,
                            16,
                            17,
                            18,
                            19,
                            20,
                            21,
                            22,
                            23,
                            24,
                            25
                        ]
                    },
                    "completionList": {
                        "itemDefaults": [
                            "commitCharacters",
                            "editRange",
                            "insertTextFormat",
                            "insertTextMode"
                        ]
                    }
                },
                "hover": {
                    "dynamicRegistration": true,
                    "contentFormat": [
                        "markdown",
                        "plaintext"
                    ]
                },
                "signatureHelp": {
                    "dynamicRegistration": true,
                    "signatureInformation": {
                        "documentationFormat": [
                            "markdown",
                            "plaintext"
                        ],
                        "parameterInformation": {
                            "labelOffsetSupport": true
                        },
                        "activeParameterSupport": true
                    },
                    "contextSupport": true
                },
                "definition": {
                    "dynamicRegistration": true,
                    "linkSupport": true
                },
                "references": {
                    "dynamicRegistration": true
                },
                "documentHighlight": {
                    "dynamicRegistration": true
                },
                "documentSymbol": {
                    "dynamicRegistration": true,
                    "symbolKind": {
                        "valueSet": [
                            1,
                            2,
                            3,
                            4,
                            5,
                            6,
                            7,
                            8,
                            9,
                            10,
                            11,
                            12,
                            13,
                            14,
                            15,
                            16,
                            17,
                            18,
                            19,
                            20,
                            21,
                            22,
                            23,
                            24,
                            25,
                            26
                        ]
                    },
                    "hierarchicalDocumentSymbolSupport": true,
                    "tagSupport": {
                        "valueSet": [
                            1
                        ]
                    },
                    "labelSupport": true
                },
                "codeAction": {
                    "dynamicRegistration": true,
                    "isPreferredSupport": true,
                    "disabledSupport": true,
                    "dataSupport": true,
                    "resolveSupport": {
                        "properties": [
                            "edit"
                        ]
                    },
                    "codeActionLiteralSupport": {
                        "codeActionKind": {
                            "valueSet": [
                                "",
                                "quickfix",
                                "refactor",
                                "refactor.extract",
                                "refactor.inline",
                                "refactor.rewrite",
                                "source",
                                "source.organizeImports"
                            ]
                        }
                    },
                    "honorsChangeAnnotations": false
                },
                "codeLens": {
                    "dynamicRegistration": true
                },
                "formatting": {
                    "dynamicRegistration": true
                },
                "rangeFormatting": {
                    "dynamicRegistration": true
                },
                "onTypeFormatting": {
                    "dynamicRegistration": true
                },
                "rename": {
                    "dynamicRegistration": true,
                    "prepareSupport": true,
                    "prepareSupportDefaultBehavior": 1,
                    "honorsChangeAnnotations": true
                },
                "documentLink": {
                    "dynamicRegistration": true,
                    "tooltipSupport": true
                },
                "typeDefinition": {
                    "dynamicRegistration": true,
                    "linkSupport": true
                },
                "implementation": {
                    "dynamicRegistration": true,
                    "linkSupport": true
                },
                "colorProvider": {
                    "dynamicRegistration": true
                },
                "foldingRange": {
                    "dynamicRegistration": true,
                    "rangeLimit": 5000,
                    "lineFoldingOnly": true,
                    "foldingRangeKind": {
                        "valueSet": [
                            "comment",
                            "imports",
                            "region"
                        ]
                    },
                    "foldingRange": {
                        "collapsedText": false
                    }
                },
                "declaration": {
                    "dynamicRegistration": true,
                    "linkSupport": true
                },
                "selectionRange": {
                    "dynamicRegistration": true
                },
                "callHierarchy": {
                    "dynamicRegistration": true
                },
                "semanticTokens": {
                    "dynamicRegistration": true,
                    "tokenTypes": [
                        "namespace",
                        "type",
                        "class",
                        "enum",
                        "interface",
                        "struct",
                        "typeParameter",
                        "parameter",
                        "variable",
                        "property",
                        "enumMember",
                        "event",
                        "function",
                        "method",
                        "macro",
                        "keyword",
                        "modifier",
                        "comment",
                        "string",
                        "number",
                        "regexp",
                        "operator",
                        "decorator"
                    ],
                    "tokenModifiers": [
                        "declaration",
                        "definition",
                        "readonly",
                        "static",
                        "deprecated",
                        "abstract",
                        "async",
                        "modification",
                        "documentation",
                        "defaultLibrary"
                    ],
                    "formats": [
                        "relative"
                    ],
                    "requests": {
                        "range": true,
                        "full": {
                            "delta": true
                        }
                    },
                    "multilineTokenSupport": false,
                    "overlappingTokenSupport": false,
                    "serverCancelSupport": true,
                    "augmentsSyntaxTokens": true
                },
                "linkedEditingRange": {
                    "dynamicRegistration": true
                },
                "typeHierarchy": {
                    "dynamicRegistration": true
                },
                "inlineValue": {
                    "dynamicRegistration": true
                },
                "inlayHint": {
                    "dynamicRegistration": true,
                    "resolveSupport": {
                        "properties": [
                            "tooltip",
                            "textEdits",
                            "label.tooltip",
                            "label.location",
                            "label.command"
                        ]
                    }
                },
                "diagnostic": {
                    "dynamicRegistration": true,
                    "relatedDocumentSupport": false
                }
            },
            "window": {
                "showMessage": {
                    "messageActionItem": {
                        "additionalPropertiesSupport": true
                    }
                },
                "showDocument": {
                    "support": true
                },
                "workDoneProgress": true
            },
            "general": {
                "staleRequestSupport": {
                    "cancel": true,
                    "retryOnContentModified": [
                        "textDocument/semanticTokens/full",
                        "textDocument/semanticTokens/range",
                        "textDocument/semanticTokens/full/delta"
                    ]
                },
                "regularExpressions": {
                    "engine": "ECMAScript",
                    "version": "ES2020"
                },
                "markdown": {
                    "parser": "marked",
                    "version": "1.1.0"
                },
                "positionEncodings": [
                    "utf-16"
                ]
            },
            "notebookDocument": {
                "synchronization": {
                    "dynamicRegistration": true,
                    "executionSummarySupport": true
                }
            }
        },
        "trace": "off",
        "workspaceFolders": [
            {
                "uri": "file:///Users/jairocaro-accinoviciana/pony-example",
                "name": "pony-example"
            }
        ]
    }
}*/