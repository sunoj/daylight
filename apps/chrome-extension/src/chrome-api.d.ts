/**
 * Minimal Chrome extension API declarations used by the rewrite slice.
 * Exports: global chrome namespace declarations
 * Deps: DOM ImageData type
 */

declare namespace chrome {
  namespace action {
    function setIcon(details: { readonly imageData: ImageData }): void;
    function setTitle(details: { readonly title: string }): void;
  }

  namespace alarms {
    interface Alarm {
      readonly name: string;
    }

    function create(name: string, info: { readonly delayInMinutes?: number; readonly periodInMinutes?: number }): void;
    function clear(name: string): Promise<boolean>;
    const onAlarm: ChromeEvent<(alarm: Alarm) => void>;
  }

  namespace runtime {
    interface Manifest {
      readonly version: string;
    }

    const onInstalled: ChromeEvent<() => void>;
    const onStartup: ChromeEvent<() => void>;
    const onMessage: ChromeEvent<(message: unknown) => void>;
    function getManifest(): Manifest;
    function getURL(path: string): string;
    function openOptionsPage(): void;
    function sendMessage(message: unknown): void;
  }

  namespace tabs {
    function create(createProperties: { readonly url: string }): Promise<void>;
  }

  namespace permissions {
    interface Permissions {
      readonly origins?: readonly string[];
    }

    function contains(permissions: Permissions): Promise<boolean>;
    function request(permissions: Permissions): Promise<boolean>;
  }

  namespace i18n {
    function getUILanguage(): string;
  }

  namespace storage {
    interface StorageArea {
      get(keys?: readonly string[] | string | Record<string, unknown> | null): Promise<Record<string, unknown>>;
      set(items: Record<string, unknown>): Promise<void>;
      remove(keys: readonly string[] | string): Promise<void>;
    }

    const local: StorageArea;
    const sync: StorageArea;
  }

  interface ChromeEvent<TListener extends (...args: never[]) => void> {
    addListener(listener: TListener): void;
  }
}
