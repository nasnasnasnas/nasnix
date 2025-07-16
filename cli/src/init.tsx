import mri from 'mri';
import type { Type } from 'arktype'
import type { JSX } from 'react'

type Command<T> = {
    command: string
    description: string
    usage: string
    argTypes: Type<T>
    component: (props: { args: Type<T>['infer'] }) => JSX.Element
}

type Commands = {
    [key: string]: Commands | Command<any>
}

// Import all commands and create a map
const commands: Commands = {
    help: await import('./commands/help.tsx'),
    sub: {
        subcommand: await import('./commands/sub/subcommand.tsx'),
    },
}

// Figure out which command we should be running (commands can be arbitrarily nested)
const args = mri(process.argv.slice(2), {
    boolean: ['help'],
    alias: { h: 'help' },
});

const commandPath = args._.length > 0 ? args._.join('.') : 'help';
const command = commandPath.split('.').reduce((cmd, part) => {
    if (cmd && typeof cmd === 'object' && part in cmd) {
        return cmd[part];
    }
}, commands);

if (!command || typeof command !== 'object' || !('component' in command)) {
    console.error(`Unknown command: ${commandPath}`);
    process.exit(1);
}
