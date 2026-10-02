.pragma library

function parse(raw) {
  var items = []
  try {
    var parsed = JSON.parse(raw)
    if (parsed && Array.isArray(parsed.items)) {
      for (var i = 0; i < parsed.items.length; i++) {
        var it = parsed.items[i]
        if (it && typeof it.text === "string")
          items.push({ id: Number(it.id) || (i + 1), text: it.text, done: it.done === true })
      }
    }
  } catch (e) {}
  return items
}

function serialize(items) {
  return JSON.stringify({ items: items }) + "\n"
}

function add(items, text) {
  var t = String(text).trim()
  if (!t) return items
  var maxId = 0
  for (var i = 0; i < items.length; i++) maxId = Math.max(maxId, items[i].id)
  return items.concat([{ id: maxId + 1, text: t, done: false }])
}

function toggle(items, id) {
  return items.map(function (it) {
    return it.id === id ? { id: it.id, text: it.text, done: !it.done } : it
  })
}

function remove(items, id) {
  return items.filter(function (it) { return it.id !== id })
}

function clearDone(items) {
  return items.filter(function (it) { return !it.done })
}

function remaining(items) {
  return items.filter(function (it) { return !it.done }).length
}
