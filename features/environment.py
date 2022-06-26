from subprocess import check_call, DEVNULL


def before_scenario(context, _):
    check_call(['rm', '-rf', 'build'], stdout=DEVNULL, stderr=DEVNULL)
    check_call(['bin/build_elf'])


def after_scenario(context, _):
    if "process" in context and context.process:
        context.process.kill()
