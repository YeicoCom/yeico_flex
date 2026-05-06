import { minimalSetup } from "codemirror"
import { EditorView, keymap, lineNumbers } from "@codemirror/view"
import { EditorState, Compartment } from "@codemirror/state"
import { elixir } from "codemirror-lang-elixir"
import { oneDark } from "@codemirror/theme-one-dark"
import { indentWithTab } from "@codemirror/commands"

export default function Editor(id, codeKey, onKey) {
    let language = new Compartment
    let state = EditorState.create({
        doc: localStorage.getItem(codeKey),
        extensions: [
            EditorView.domEventHandlers({
                keydown: (e) => {
                    //console.log(e)
                    if ((e.metaKey || e.ctrlKey)) return onKey(e.key, this)
                }
            }),
            minimalSetup,
            lineNumbers(),
            keymap.of([indentWithTab]),
            language.of(elixir()),
            ...oneDark,
            EditorView.updateListener.of((e) => {
                if (e.docChanged) {
                    // console.log(e)
                    code = e.state.doc.toString()
                    localStorage.setItem(codeKey, code)
                }
            })
        ]
    })
    let container = document.getElementById(id)
    let view = new EditorView({ state: state, parent: container })
    this.toString = () => { return view.state.doc.toString() }
    this.replace = (text) => {
        view.dispatch({
            changes: {
                from: 0,
                to: view.state.doc.length,
                insert: text
            }
        })
    }
    this.focus = () => {
        view.focus()
    }
    this.handleEvent = (params) => {
        //console.log(params)
        this.replace(params.code)
    }
    container.addEventListener("click", (e) => {
        view.focus()
    })
}