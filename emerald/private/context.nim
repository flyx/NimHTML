import sets, "../tagdef"

type
    TOutputMode* = enum
        unknown, blockmode, flowmode

    TContext* = object
        mode*: TOutputMode
        nodeDepth: int
        forbiddenTags: TSet[string]
        forbiddenCategories: set[TContentCategory]
        permittedTags: TSet[string]
        permittedContent: set[TContentCategory]

    PContext* = ref TContext

proc initContext*(acceptAny: bool = false, mode: TOutputMode = unknown,
                  indent: int = -1): PContext =
    new(result)
    result.mode = mode
    result.nodeDepth = indent
    result.forbiddenCategories = {}
    result.forbiddenTags = initSet[string]()
    result.permittedContent = {}
    result.permittedTags = initSet[string]()
    if acceptAny:
        result.permittedContent.incl(any_content)
    else:
        result.permittedTags.incl("html")

proc depth*(context: PContext): int {.inline.} =
    return context.nodeDepth

proc enter*(context: PContext, tag: TTagDef): PContext =
    new(result)
    result.mode = if context.mode == flowmode: flowmode else: unknown
    result.nodeDepth = context.nodeDepth + 1
    result.forbiddenTags = context.forbiddenTags + tag.forbiddenTags
    result.forbiddenCategories = context.forbiddenCategories
    for i in tag.forbiddenContent: result.forbiddenCategories.incl(i)
    # SIGSEGV! (probably a compiler bug; works at runtime, but not at compiletime)
    #result.forbiddenCategories = context.forbiddenCategories + tag.forbiddenContent

    if tag.permittedContent.contains(transparent):
        result.permittedContent = context.permittedContent
        result.permittedTags = context.permittedTags
    else:
        result.permittedTags = tag.permittedTags
        result.permittedContent = tag.permittedContent

proc accepts*(context: PContext, tagName: string, tag: TTagDef): bool =
    result = false
    if context.permittedContent.contains(any_content): return true
    if context.forbiddenTags.contains(tagName): return false
    if context.permittedTags.contains(tagName): result = true
    for category in tag.contentCategories:
        if context.forbiddenCategories.contains(category):
            return false
        if context.permittedContent.contains(category):
            result = true
    
