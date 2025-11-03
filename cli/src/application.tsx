import { exit } from 'node:process'
import { Box, render, Text } from 'ink'
import pkg from '../package.json'

type ApplicationProps = {
    name: string;
    version: string;
}

export const Application = ({ name, version }: ApplicationProps) => {
    const NEA_PURPLE = '#c49ed5'

    return (
        <Box width={80} paddingX={1} flexDirection="column">
            <Box
                borderStyle="round"
                paddingX={1}
                borderColor={NEA_PURPLE}
                flexDirection="column"
            >
                <Box paddingBottom={1}>
                    <Text bold color={NEA_PURPLE}>NASNix Command Line Interface</Text>
                </Box>
                <Text>{name}</Text>
                <Text>version: {version}</Text>
            </Box>
        </Box>
    )
}

try {
    const { waitUntilExit, unmount } = render(
        <Application
            name={pkg.name}
            version={pkg.version}
        />
    )
    setTimeout(unmount, 500)
    await waitUntilExit()
} catch (error) {
    console.error({ status: 'app exited with error', error })
    exit(1)
}
