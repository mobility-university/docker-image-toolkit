from behave import given, when, then
from difflib import ndiff
from subprocess import check_call, check_output, DEVNULL, Popen, PIPE
from glob import glob
import os.path
import os
import re


@when('I execute «{command}»')
def execute(context, command):
    context.result = check_output(
        [
            'docker',
            'run',
            '--rm',
            '-v',
            f'{os.getcwd()}/build/fckubi:/bin/fckubi',
            'alpine',
        ]
        + command.split(' '),
        encoding='utf-8',
    ).strip()


@then('I get')
def ensure_result(context):
    diff = ndiff(
        context.text.splitlines(keepends=True),
        context.result.splitlines(keepends=True),
    )
    message = (
        ''.join(diff) if 'diff' in os.environ else f'{context.text} != {context.result}'
    )
    assert context.text.strip() == context.result.strip(), message


@given('a file «{path}» is created')
def create_file(context, path):
    check_call(["mkdir", "-p", "build"])
    with open(f"build/{path}", "w", encoding="utf-8") as file:
        file.write(context.text)


@given("created a Docker build description like this")
def create_dockerfile(context):
    check_call(["mkdir", "-p", "build"])
    with open("build/Dockerfile", "w", encoding="utf-8") as file:
        file.write(context.text)


@given("I built this docker image")
@when("I build this docker image")
def build_docker_image(context):
    check_call(["cp", "-r", "src", "build"])

    check_call(
        ["docker", "build", "--file=build/Dockerfile", "-t=fckubi", "build"],
        stdout=PIPE if 'verbose' in os.environ else DEVNULL,
        stderr=PIPE if "verbose" in os.environ else DEVNULL,
    )


@given("it needs {size} MB")
@then("it needs {size} MB")
def measure_size(context, size):
    export_files()
    actual = f'{os.path.getsize("build/fckubi.tar") / 1024 / 1024:.1f}'
    assert size == actual, f'{actual} != {size}'


@then("instantiating this image in the background with")
def instantiate_in_background(context):
    assert len(list(context.table)) == 1
    (row,) = list(context.table)
    options = []
    if "options" in row.headings:
        options = row["options"].split(" ")
    command = []
    if "command" in row.headings:
        command = row["command"].split(" ")
    try:
        check_call(
            ["docker", "stop", "fckubi"],
            stdout=PIPE if 'verbose' in os.environ else DEVNULL,
            stderr=PIPE if 'verbose' in os.environ else DEVNULL,
        )
    except:
        ...
    try:
        check_call(
            ["docker", "rm", "fckubi"],
            stdout=PIPE if 'verbose' in os.environ else DEVNULL,
            stderr=PIPE if 'verbose' in os.environ else DEVNULL,
        )
    except:
        ...
    context.process = Popen(
        ["docker", "run", "--rm", "--name=fckubi"] + options + ["fckubi"] + command,
        stdout=PIPE if 'verbose' in os.environ else DEVNULL,
        stderr=PIPE if 'verbose' in os.environ else DEVNULL,
    )
    import time

    time.sleep(1)


@then('running «{command}» results in')
def check_output_of_command(context, command):
    out = check_output(command.split(" ")).decode("utf-8").strip()  # TODO: shlex
    assert out == context.text.strip(), f"{out} does not match {context.text}"


@then("it contains the following files")
@then("the image contains the following files")
def check_files(context):
    actual = sort_lines(export_files())
    expected = sort_lines(context.text.strip())
    if '...' in context.text:
        # use regex
        print(expected.replace('.', '\\.').replace('-', '\\-').replace('...', '.*'))
        assert False, (
            expected.replace('.', '\\.').replace('-', '\\-').replace('\\.\\.\\.', '.*')
        )
        assert re.match(
            expected.replace('.', '\\.').replace('-', '\\-').replace('\\.\\.\\.', '.*'),
            actual,
        ), f"{actual} does not match {expected}"
    else:
        message = (
            ''.join(
                ndiff(
                    actual.splitlines(keepends=True), expected.splitlines(keepends=True)
                )
            )
            if 'diff' in os.environ
            else f"{actual} does not match {expected}"
        )
        assert actual == expected, message


@then('instantiating the image with command «{command}» results in')
def check_output_of_docker(context, command):
    out = (
        check_output(["docker", "run", "--rm", "fckubi"] + command.split(" "))
        .decode("utf-8")
        .strip()
    )  # TODO: shlex
    assert out == context.text.strip(), f"{out} does not match {context.text}"


@given('it contains {amount:d} files')
@then('it contains {amount:d} files')
def ensure_files(context, amount):
    for file in export_files().splitlines():
        print(f' - {file}')
    actual = len(export_files().splitlines())
    assert actual == amount, f'{actual} != {amount}'
    base_line = get_base_line()
    print(f'base: {len(base_line)}')


def get_base_line():
    check_call(['mkdir', '-p', 'build'])
    with open('build/Dockerfile', 'w', encoding='utf-8') as file:
        file.write('FROM alpine')
    check_call(
        ['docker', 'build', '--file=build/Dockerfile', '--tag=scratch-base', 'build']
    )

    return export_files(destination='build/scratch', image='scratch-base').splitlines()


@then('it contains no links')
def ensure_no_links(context):
    links = [
        path
        for path in export_files().splitlines()
        if os.path.islink(f'build/export/{path}')
    ]
    assert not links


@then('it contains the following links')
def ensure_links(context):
    links = [
        f'{path} -> {os.readlink(f"build/export/{path}")}'
        for path in export_files().splitlines()
        if os.path.islink(f'build/export/{path}')
    ]

    actual = '\n'.join(sorted(links))
    expected = context.text.strip()
    assert actual == expected, f'{actual} != {expected}'


def export_files(destination='build/export', image='fckubi'):
    def is_system_file(path):  # TODO: diff from scratch
        if path.startswith(f"{destination}/etc"):
            return True
        if path.startswith(f"{destination}/proc"):
            return True
        if path.startswith(f"{destination}/sys"):
            return True
        return path.startswith(f"{destination}/dev")

    container = (
        check_output(["docker", "create", image, "not-specified"])
        .decode("utf-8")
        .strip()
    )
    check_call(["rm", "-rf", destination])
    check_call(["mkdir", "-p", destination])

    check_call(["docker", "export", container, "-o", f"build/{image}.tar"])
    check_call(["tar", "xf", f"build/{image}.tar", "-C", destination])
    lena = len(f"{destination}/")
    return "\n".join(
        file[lena:]
        for file in glob(f"{destination}/**", recursive=True)
        if not is_system_file(file) and not os.path.isdir(file)
    ).strip()


def sort_lines(value):
    return '\n'.join(sorted(value.splitlines()))
