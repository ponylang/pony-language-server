use "files"

primitive Uris
  fun to_path(uri: String): String =>
    """
    Ensure an LSP uri (https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#uri)
    is converted to a path, so the `schema://` needs to be dropped, if present.
    """
    let result = uri.split_by("://", 2)
    try
      result(result.size() - 1)?
    else
      // shouldn't happen, given that split_by never returns an empty array
      uri
    end
