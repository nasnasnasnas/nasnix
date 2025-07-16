import { type } from 'arktype'
import { theme } from '../../theme.ts'
import { Text } from 'ink'

export const command = 'subcommand'
export const description = 'Test subcommand for NASNix CLI'
export const usage = 'nasnix sub subcommand <num>'

export const argTypes = type({
    num: 'number',
})

export const component = ({ args }: { args: typeof argTypes.infer }) =>
{
    const { num } = args

    return (
        <Text color={theme.primaryColor}>{ num }</Text>
    )
}