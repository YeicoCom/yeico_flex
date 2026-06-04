import { minimalSetup } from "codemirror"
import { EditorView, keymap, lineNumbers } from "@codemirror/view"
import { EditorState, Compartment } from "@codemirror/state"
import { elixir } from "codemirror-lang-elixir"
import { oneDark } from "@codemirror/theme-one-dark"
import { indentWithTab } from "@codemirror/commands"
import { historyField } from "@codemirror/commands"

export default function Editor(parent, stateKey, onSave) {
    const extensions = [
        EditorView.domEventHandlers({
            keydown: (e) => {
                if ((e.metaKey || e.ctrlKey)) {
                    if (e.key == "s") {
                        e.preventDefault() //disable browser save dialog
                        return onSave(this)
                    }
                }
            }
        }),
        minimalSetup,
        lineNumbers(),
        keymap.of([indentWithTab]),
        (new Compartment).of(elixir()),
        ...oneDark,
        EditorView.updateListener.of((e) => {
            if (e.docChanged) {
                const json = JSON.stringify(e.state.toJSON({ history: historyField }))
                localStorage.setItem(stateKey, json)
            }
        })
    ]
    const json = localStorage.getItem(stateKey)
    let state = json ? EditorState.fromJSON(JSON.parse(json), { extensions }, { history: historyField }) : EditorState.create({ extensions })
    let view = new EditorView({ state: state, parent: parent })
    this.toString = () => { return view.state.doc.toString() }
    this.replace = (text) => {
        view.dispatch({
            changes: {
                from: 0,
                to: view.state.doc.length,
                insert: text
            }
        })
        // cursor to pos zero
        view.dispatch({ selection: { anchor: 0 } })
    }
    this.focus = () => {
        view.focus()
    }
    parent.addEventListener("click", (e) => {
        view.focus()
    })
}