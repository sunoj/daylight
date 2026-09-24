/**
 * Minimal DOM shim for Chrome extension unit tests in Node.
 * Exports: installTestDom
 * Deps: none
 */

type Listener = (event?: { readonly type: string }) => void;

interface MockNode {
  readonly tagName: string;
  className: string;
  textContent: string;
  type: string;
  title: string;
  readonly children: MockNode[];
  readonly classList: {
    add(...names: string[]): void;
    remove(...names: string[]): void;
    readonly contains: (name: string) => boolean;
  };
  replaceChildren(...nodes: MockNode[]): void;
  append(...nodes: MockNode[]): void;
  addEventListener(type: string, listener: Listener): void;
  click(): void;
  setAttribute(name: string, value: string): void;
  getAttribute(name: string): string | null;
  querySelector(selector: string): MockNode | undefined;
  querySelectorAll(selector: string): MockNode[];
}

export function installTestDom(): void {
  if (typeof globalThis.document !== "undefined") return;

  class MockElement implements MockNode {
    readonly tagName: string;
    className = "";
    textContent = "";
    type = "";
    title = "";
    readonly children: MockNode[] = [];
    private readonly listeners = new Map<string, Listener[]>();
    private readonly attributes = new Map<string, string>();
    readonly classList = {
      add: (...names: string[]) => {
        const current = new Set(this.className.split(/\s+/).filter(Boolean));
        for (const name of names) current.add(name);
        this.className = [...current].join(" ");
      },
      remove: (...names: string[]) => {
        const current = new Set(this.className.split(/\s+/).filter(Boolean));
        for (const name of names) current.delete(name);
        this.className = [...current].join(" ");
      },
      contains: (name: string) => this.className.split(/\s+/).includes(name),
    };

    constructor(tagName: string) {
      this.tagName = tagName.toUpperCase();
    }

    replaceChildren(...nodes: MockNode[]): void {
      this.children.length = 0;
      this.children.push(...nodes);
    }

    append(...nodes: MockNode[]): void {
      this.children.push(...nodes);
    }

    addEventListener(type: string, listener: Listener): void {
      const existing = this.listeners.get(type) ?? [];
      existing.push(listener);
      this.listeners.set(type, existing);
    }

    click(): void {
      for (const listener of this.listeners.get("click") ?? []) listener({ type: "click" });
    }

    setAttribute(name: string, value: string): void {
      this.attributes.set(name, value);
    }

    getAttribute(name: string): string | null {
      return this.attributes.get(name) ?? null;
    }

    querySelector(selector: string): MockNode | undefined {
      return this.querySelectorAll(selector)[0];
    }

    querySelectorAll(selector: string): MockNode[] {
      const className = selector.startsWith(".") ? selector.slice(1) : "";
      return collectMatches(this, className);
    }
  }

  class MockKeyboardEvent {
    readonly key: string;
    readonly code: string;
    readonly shiftKey: boolean;
    target: EventTarget | null = null;

    constructor(_type: string, init?: KeyboardEventInit & { readonly target?: EventTarget | null }) {
      this.key = init?.key ?? "";
      this.code = init?.code ?? "";
      this.shiftKey = init?.shiftKey ?? false;
      if (init?.target !== undefined) this.target = init.target;
    }

    preventDefault(): void {}
  }

  globalThis.HTMLElement = MockElement as unknown as typeof HTMLElement;
  globalThis.KeyboardEvent = MockKeyboardEvent as unknown as typeof KeyboardEvent;
  globalThis.document = {
    createElement(tag: string) {
      return new MockElement(tag);
    },
  } as Document;
}

function collectMatches(root: MockNode, className: string): MockNode[] {
  const matches: MockNode[] = [];
  walk(root, (node) => {
    if (node.className.split(/\s+/).includes(className)) matches.push(node);
  });
  return matches;
}

function walk(node: MockNode, visit: (node: MockNode) => void): void {
  visit(node);
  for (const child of node.children) walk(child, visit);
}
