%global scl gdc-adriana
%global _scl_prefix /opt/gdc
%global pkg_name adriana
%{?scl_package:%scl_package adriana}

%{!?scl_ruby:%global scl_ruby rh-ruby24}
%{!?scl_prefix_ruby:%global scl_prefix_ruby %{scl_ruby}-}

%global scl_upper %{lua:print(string.upper(string.gsub(rpm.expand("%{scl}"), "-", "_")))}
%global debug_package %{nil}

Name:           %{?scl_prefix}adriana
Version:        2
Release:        1%{?dist}
Summary:        The ETL monitoring app (code name Adriana)
Group:          Applications/Internet
License:        GPL
Source0:        %{pkg_name}.tar.gz
Source1:        %{pkg_name}.service

BuildRequires: scl-utils-build
BuildRequires: %{scl_prefix_ruby}scldevel
BuildRequires: %{scl_prefix_ruby}ruby-devel
BuildRequires: %{scl_prefix_ruby}rubygems-devel
BuildRequires: %{scl_prefix_ruby}rubygem(bundler)
BuildRequires: gcc
BuildRequires: gcc-c++
BuildRequires: psmisc
BuildRequires: zlib-devel
BuildRequires: postgresql96-server
BuildRequires: postgresql96-devel
BuildRequires: systemd-units
BuildRequires: centos-release-scl


Requires(pre): shadow-utils
Requires: %{scl_prefix_ruby}ruby
Requires: %{scl_prefix_ruby}ruby(rubygems)
Requires: %{scl_prefix_ruby}rubygem(bundler)

AutoReq: no

%global appdir %{_datadir}/%{pkg_name}
%global bindir %{homedir}/bin
%global confdir %{_root_sysconfdir}/%{pkg_name}
%global logdir /mnt/log/%{pkg_name}
%global tmpdir %{_tmppath}/%{pkg_name}

%global pgroot /usr/pgsql-9.6

%description
The ETL monitoring application (code name Adriana by it's architect, Adrian Toman)

%prep
%setup -q %{?scl: -n %{pkg_name}-%{version}}
rm -f .gitignore

%build
# Compile assets
cat > config/database.yml <<"EODBCONFIG"
production:
  adapter: postgresql
  host: localhost
  port: 25432
  database: build
  template: template0
  username: build
  password: build
EODBCONFIG

fuser -k -n tcp 25432 2>/dev/null || true
rm -Rf temp_db
%{pgroot}/bin/pg_ctl init -D temp_db -w
%{pgroot}/bin/pg_ctl start -o '-p 25432 -k /tmp' -D temp_db -w
%{pgroot}/bin/createuser -p 25432 -h /tmp -S -R -d -e build
%{pgroot}/bin/createdb -p 25432 -h /tmp -O build -T template0 -e build

%{?scl:scl enable %{scl_ruby} - << EOF}
  set -a -e -x

  RAILS_ENV=production
  BUNDLE_BUILD__PG=--with-pg-config=%{pgroot}/bin/pg_config

  bundle install --deployment --jobs=4 --without=development:test --local

  { echo 'production:'; echo -n '  secret_key_base: '; bin/rake secret ; } > config/secrets.yml

  bundle exec rake db:setup

  rm -rf ./public/assets
  bundle exec rake assets:precompile

  rm -rf tmp/
  bundle exec rake tmp:create
%{?scl:EOF}

%{pgroot}/bin/pg_ctl stop -o '-h /tmp' -D temp_db -w
rm -rf temp_db


%install
install -d %{buildroot}%{appdir}
install -d %{buildroot}%{_initddir}
install -d %{buildroot}%{_bindir}
install -d %{buildroot}%{logdir}
install -d %{buildroot}%{confdir}
install -d %{buildroot}%{_unitdir}

find vendor/bundle -name pg_ext.so -exec chrpath -d '{}' \;

cp -r -l * %{buildroot}%{appdir}
mv %{buildroot}%{appdir}/config/* %{buildroot}%{confdir}
rm -rf %{buildroot}%{appdir}/{config,log,test,vendor/cache,vendor/bundle/ruby/cache}

ln -sfn %{logdir} %{buildroot}%{appdir}/log
%{?scl:ln -sfn %_root_sysconfdir/%{pkg_name} %{buildroot}%{appdir}/config}

install -d %{buildroot}%{appdir}/.bundle
cat > %{buildroot}%{appdir}/.bundle/config << "EOF"
---
BUNDLE_FROZEN: "true"
BUNDLE_PATH: "vendor/bundle"
BUNDLE_WITHOUT: "development:test"
BUNDLE_DISABLE_SHARED_GEMS: "true"
EOF

find %{buildroot}%{appdir} -type f -exec chmod -x '{}' +
chmod 0755 %{buildroot}%{appdir}/bin/*

cat << EOF | tee -a %{buildroot}%{?_scl_scripts}/service-environment
%{scl_upper}_SCLS_ENABLED="%{scl_ruby}"
EOF
install -m 0644 %{SOURCE1} %{buildroot}%{_unitdir}/%{pkg_name}.service

%files
%defattr(-,root,root,-)
%{appdir}
%dir %attr(-,adriana,adriana) %{logdir}
%config %attr(0750,root,adriana) %{confdir}
%{_unitdir}
%config(noreplace) %{?_scl_scripts}/service-environment


%pre
groupadd -r adriana 2>/dev/null || :
useradd -c "Adriana" -g adriana -s /sbin/nologin -r -d %{appdir} adriana 2>/dev/null || :

%post
if [ $1 -eq 1 ] && [ -s %{confdir}/secrets.yml ] ; then
  { echo 'production:'; echo -n '  secret_key_base: '; bin/rake secret ; } > %{confdir}/secrets.yml
fi
%systemd_post %{pkg_name}.service

%preun
%systemd_preun %{pkg_name}.service

%postun
%systemd_postun_with_restart %{pkg_name}.service
