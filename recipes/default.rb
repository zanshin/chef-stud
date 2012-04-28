#
# Cookbook Name:: stud
# Recipe:: default
#
# Copyright 2012, CX Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
include_recipe "runit"
include_recipe "git"
include_recipe "build-essential"

package "libssl-dev"
package "libev-dev"

user node[:stud][:user]
group node[:stud][:group]

execute "install-stud" do
  cwd node[:stud][:src_dir]
  command "make install"
  creates "#{node[:stud][:dst_dir]}/stud"
  user "root"
  action :nothing
end

execute "make-stud" do
  cwd node[:stud][:src_dir]
  command "make"
  creates "stud"
  user node[:stud][:user]
  action :nothing
  notifies :run, resources(:execute => "install-stud"), :immediately
end

execute "git-checkout" do
  command "git checkout #{node[:stud][:branch_tag]}"
  cwd node[:stud][:src_dir]
  user node[:stud][:user]
  action :nothing
  notifies :run, resources(:execute => "make-stud"), :immediately
end

execute "git-clone" do
  command "git clone #{node[:stud][:repo]} #{node[:stud][:src_dir]}"
  creates "#{node[:stud][:src_dir]}/Makefile"
  user node[:stud][:user]
  action :nothing
  notifies :run, resources(:execute => "git-checkout"), :immediately
end

directory "src_dir" do
  path "#{node[:stud][:src_dir]}"
  owner node[:stud][:user]
  group node[:stud][:group]
  action :create
  notifies :run, resources(:execute => "git-clone"), :immediately
end

runit_service "stud"
