namespace Sdnx.Tests;

public static class TestHelpers
{
    public static string Space(string value)
    {
        string spacedChars = "{}[]():,";
        string result = "";
        for (int i = 0; i < value.Length; i++)
        {
            char c = value[i];
            if (c == '"')
            {
                result += " \"";
                i++;
                while (i < value.Length)
                {
                    if (value[i] == '"')
                    {
                        if (i + 1 < value.Length && value[i + 1] == '"')
                        {
                            // Escaped quote ("")
                            result += "\"\"";
                            i += 2;
                        }
                        else
                        {
                            // End of string
                            result += value[i];
                            break;
                        }
                    }
                    else
                    {
                        result += value[i];
                        i++;
                    }
                }
            }
            else if (c == '#')
            {
                result += " #";
                i++;
                while (i < value.Length && value[i] != '\n')
                {
                    result += value[i];
                    i++;
                }
                if (i < value.Length)
                {
                    result += value[i];
                }
            }
            else if (spacedChars.Contains(c))
            {
                result += " " + c + " ";
            }
            else
            {
                result += c;
            }
        }
        return result;
    }

    public static string Unspace(string value)
    {
        string result = "";
        for (int i = 0; i < value.Length; i++)
        {
            char c = value[i];
            if (c == '"')
            {
                result += c;
                i++;
                while (i < value.Length)
                {
                    if (value[i] == '"')
                    {
                        if (i + 1 < value.Length && value[i + 1] == '"')
                        {
                            // Escaped quote ("")
                            result += "\"\"";
                            i += 2;
                        }
                        else
                        {
                            // End of string
                            result += value[i];
                            break;
                        }
                    }
                    else
                    {
                        result += value[i];
                        i++;
                    }
                }
            }
            else if (c == '#')
            {
                result += " #";
                i++;
                while (i < value.Length && value[i] != '\n')
                {
                    result += value[i];
                    i++;
                }
                if (i < value.Length)
                {
                    result += value[i];
                }
            }
            else if (c != ' ' && c != '\t' && c != '\n')
            {
                result += c;
            }
        }
        return result;
    }
}
