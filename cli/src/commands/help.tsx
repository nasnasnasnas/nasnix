import { type } from 'arktype'
import { theme } from '../theme.ts'
import { Box, Text } from 'ink'

export const command = 'help'
export const description = 'Display help information for NASNix CLI commands'
export const usage = 'nasnix help [command]'

export const argTypes = type({
    command: 'string?',
})

export const component = ({ args }: { args: typeof argTypes.infer }) =>
{
    const { command } = args

    return (
        <Box width={80} paddingX={1} flexDirection="column">
            <Box
                borderStyle="round"
                paddingX={1}
                borderColor={theme.primaryColor}
                flexDirection="column"
            >
                <Box paddingBottom={1}>
                    <Text bold color={theme.primaryColor}>NASNix Command Line Interface</Text>
                </Box>
            </Box>
        </Box>
    )
}