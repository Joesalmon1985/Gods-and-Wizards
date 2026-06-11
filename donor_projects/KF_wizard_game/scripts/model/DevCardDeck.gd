extends Node
class_name DevCardDeck

var _cards: Array[DevCard] = []

func fill_basic() -> void:
    # For now: just Victory Point cards
    _cards.clear()
    for i in range(5):   # give 5 VP cards for demo
        _cards.append(DevCard.new("VP", "Victory Point"))
    if OS.is_debug_build():
        print("[DevCardDeck] Filled with %d VP cards" % _cards.size())

func shuffle() -> void:
    _cards.shuffle()
    if OS.is_debug_build():
        print("[DevCardDeck] Shuffled")

func is_empty() -> bool:
    return _cards.is_empty()

func draw() -> DevCard:
    if _cards.is_empty():
        push_warning("[DevCardDeck] Attempt to draw from empty deck")
        return null
    var c: DevCard = _cards.pop_back()
    if OS.is_debug_build():
        print("[DevCardDeck] Drew card: %s" % c.debug_string())
    return c

func size() -> int:
    return _cards.size()

