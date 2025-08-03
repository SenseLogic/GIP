/*
    This file is part of the Gip distribution.

    https://github.com/senselogic/GIP

    Copyright (C) 2020 Eric Pelzer (ecstatic.coder@gmail.com)

    Gip is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3.

    Gip is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Gip.  If not, see <http://www.gnu.org/licenses/>.
*/

// -- IMPORTS

import core.stdc.stdlib : exit;
import std.ascii : isOctalDigit;
import std.conv : to;
import std.file : dirEntries, exists, isDir, getSize, SpanMode;
import std.process : executeShell, spawnShell, wait;
import std.stdio : writeln;
import std.string : endsWith, replace, split, startsWith, stripRight;

// -- TYPES

struct COMMAND_RESULT
{
    int
        Status;
    string
        Text;
}

// -- FUNCTIONS

void PrintError(
    string message
    )
{
    writeln( "*** ERROR : ", message );
}

// ~~

void Abort(
    string message
    )
{
    PrintError( message );

    exit( -1 );
}

// ~~

void Abort(
    string message,
    Exception exception
    )
{
    PrintError( message );
    PrintError( exception.msg );

    exit( -1 );
}

// ~~

bool IsFolder(
    string path
    )
{
    return
        path.exists()
        && path.isDir();
}

// ~~

string GetLogicalFilePath(
    string file_path
    )
{
    int
        character;
    long
        character_index;
    string
        logical_file_path;

    if ( file_path.startsWith( '"' )
         && file_path.endsWith( '"' ) )
    {
        file_path = file_path[ 1 .. $ - 1 ];

        for ( character_index = 0;
              character_index < file_path.length;
              ++character_index )
        {
            if ( file_path[ character_index ] == '\\'
                 && character_index + 3 < file_path.length
                 && isOctalDigit( file_path[ character_index + 1 ] )
                 && isOctalDigit( file_path[ character_index + 2 ] )
                 && isOctalDigit( file_path[ character_index + 3 ] )
                 && ( logical_file_path.endsWith( '/' )
                      || !logical_file_path.IsFolder() ) )
            {
                character = to!int( file_path[ character_index + 1 .. character_index + 4 ], 8 );
                logical_file_path ~= cast( char )character;
                character_index += 3;
            }
            else
            {
                logical_file_path ~= file_path[ character_index ];
            }
        }

        return cast( string )logical_file_path;
    }
    else
    {
        return file_path;
    }
}

// ~~

string GetQuotedFilePath(
    string file_path
    )
{
    return "\"" ~ file_path ~ "\"";
}

// ~~

string GetQuotedText(
    string text
    )
{
    return "\"" ~ text.replace( "\"", "\\\"" ) ~ "\"";
}

// ~~

COMMAND_RESULT ExecuteCommand(
    string command
    )
{
    COMMAND_RESULT
        command_result;

    writeln( "Running : ", command );

    auto result = executeShell( command );

    command_result.Status = result.status;
    command_result.Text = result.output;

    if ( command_result.Text != "" )
    {
        writeln( command_result.Text.stripRight() );
    }

    return command_result;
}

// ~~

void RunCommand(
    string command
    )
{
    writeln( "Running : ", command );

    wait( spawnShell( command ) );
}

// ~~

string[] GetCommitFileStatusArray(
    string text
    )
{
    string
        commit_file_prefix,
        commit_file_path;
    string[]
        commit_file_status_array;

    foreach ( commit_file_status; text.replace( "\r", "" ).split( '\n' ) )
    {
        if ( commit_file_status.length > 3
             && commit_file_status[ 2 ] == ' ' )
        {
            commit_file_prefix = commit_file_status[ 0 .. 3 ];
            commit_file_path = commit_file_status[ 3 .. $ ].GetLogicalFilePath();

            if ( commit_file_prefix[ 1 ] == 'D' )
            {
                writeln( "Removed : ", commit_file_path );
                commit_file_status_array ~= commit_file_prefix ~ commit_file_path;
            }
            else
            {
                if ( commit_file_path.IsFolder() )
                {
                    writeln( "Updated : ", commit_file_path );

                    foreach ( folder_entry; dirEntries( commit_file_path, SpanMode.depth ) )
                    {
                        if ( !folder_entry.isDir )
                        {
                            writeln( "Updated : ", folder_entry.name.GetLogicalFilePath() );
                            commit_file_status_array ~= commit_file_prefix ~ folder_entry.name.GetQuotedFilePath();
                        }
                    }
                }
                else
                {
                    writeln( "Updated : ", commit_file_path );
                    commit_file_status_array ~= commit_file_prefix ~ commit_file_path;
                }
            }
        }
    }

    return commit_file_status_array;
}

// ~~

string[] GetCommitFileStatusArray(
    )
{
    string[]
        commit_file_status_array;
    COMMAND_RESULT
        command_result;

    command_result = ExecuteCommand( "git status --porcelain" );

    if ( command_result.Status == 0 )
    {
        commit_file_status_array
            = GetCommitFileStatusArray( command_result.Text );
    }

    return commit_file_status_array;
}

// ~~

void ProcessFiles(
    string branch_name,
    long maximum_commit_byte_count,
    string commit_message,
    string[] filter_array
    )
{
    string
        commit_file_path,
        commit_file_prefix;
    string[]
        commit_file_status_array;
    long
        commit_byte_count,
        commit_file_byte_count;

    RunCommand( "git reset" );

    commit_file_status_array = GetCommitFileStatusArray();
    commit_byte_count = 0;

    foreach ( commit_file_status; commit_file_status_array )
    {
        commit_file_prefix = commit_file_status[ 0 .. 3 ];
        commit_file_path = commit_file_status[ 3 .. $ ].GetLogicalFilePath();

        if ( commit_file_prefix[ 1 ] == 'D'
             || commit_file_path.isDir() )
        {
            commit_file_byte_count = 0;
        }
        else
        {
            commit_file_byte_count = commit_file_path.getSize();
        }

        if ( commit_byte_count + commit_file_byte_count > maximum_commit_byte_count )
        {
            RunCommand( "git commit -m " ~ commit_message.GetQuotedText() );
            RunCommand( "git push origin " ~ branch_name );
            RunCommand( "git reset" );
            commit_byte_count = 0;
        }

        RunCommand( "git add " ~ commit_file_path.GetQuotedFilePath() );
        commit_byte_count += commit_file_byte_count;
    }

    if ( commit_byte_count > 0 )
    {
        RunCommand( "git commit -m " ~ commit_message.GetQuotedText() );
        RunCommand( "git push origin " ~ branch_name );
        RunCommand( "git reset" );
    }
}

// ~~

void main(
    string[] argument_array
    )
{
    argument_array = argument_array[ 1 .. $ ];

    if ( argument_array.length >= 3 )
    {
        ProcessFiles(
            argument_array[ 0 ],
            argument_array[ 1 ].to!long() * 1024 * 1024,
            argument_array[ 2 ],
            argument_array[ 3 .. $ ]
            );

    }
    else
    {
        writeln( "Usage :" );
        writeln( "    gip <branch name> <maximum commit size> <commit message> [<file filter> ...]" );
        writeln( "Examples :" );
        writeln( "    gip master 100 \"added initial version\"" );

        Abort( "Invalid arguments : " ~ argument_array.to!string() );
    }
}
