# project name and programming language
project('com.github.jeremyvaartjes.subminder', 'vala', 'c')

i18n = import('i18n')
add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

# Create a new executable, list the files we want to compile, list the dependencies we need, and install
executable(
    meson.project_name(),
    'src/Application.vala',
    'src/Subscription.vala',
    'src/SubscriptionListRow.vala',
    'src/SMCurrency.vala',
    'src/AddSubscriptionDialog.vala',
    'src/Settings.vala',
    'src/DefaultCurrencyDialog.vala',
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('gee-0.8'),
        dependency('json-glib-1.0'),
        dependency('granite'),
        dependency('libsoup-2.4')
    ],
    install: true
)

subdir('data')
subdir('po')

meson.add_install_script('meson/post_install.py')
