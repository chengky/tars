-- phpMyAdmin SQL Dump
-- version 3.4.10.1
-- http://www.phpmyadmin.net
--
-- 主机: 10.129.135.179:3342
-- 生成日期: 2015 年 05 月 30 日 13:51
-- 服务器版本: 5.1.54
-- PHP 版本: 5.2.14p1

SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;

--
-- 数据库: `PackageCenterOpensrc`
--
CREATE DATABASE `PackageCenterOpensrc` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `PackageCenterOpensrc`;

-- --------------------------------------------------------

--
-- 表的结构 `ProductNameMap`
--

CREATE TABLE IF NOT EXISTS `ProductNameMap` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product` varchar(20) NOT NULL COMMENT '包产品',
  `chinese` varchar(20) NOT NULL COMMENT '包名',
  PRIMARY KEY (`id`),
  UNIQUE KEY `product` (`product`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=57 ;

-- --------------------------------------------------------

--
-- 表的结构 `ZY_taskDetail`
--

CREATE TABLE IF NOT EXISTS `ZY_taskDetail` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `task_id` varchar(32) NOT NULL,
  `operate` varchar(32) NOT NULL,
  `ip` varchar(32) NOT NULL,
  `status` varchar(32) NOT NULL,
  `error` varchar(2048) NOT NULL,
  `task_info` longtext NOT NULL,
  `used_time` int(11) NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`),
  KEY `task_id` (`task_id`),
  KEY `operate` (`operate`),
  KEY `ip` (`ip`),
  KEY `status` (`status`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COMMENT='备份' AUTO_INCREMENT=116 ;

-- --------------------------------------------------------

--
-- 表的结构 `ZY_taskInfo`
--

CREATE TABLE IF NOT EXISTS `ZY_taskInfo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `task_id` varchar(32) NOT NULL,
  `op_type` varchar(32) NOT NULL,
  `operator` varchar(32) NOT NULL,
  `product` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `ip_list` longtext NOT NULL,
  `param` longtext NOT NULL,
  `task_status` varchar(32) NOT NULL,
  `hasRead` int(11) NOT NULL COMMENT '0未读, 1已读',
  `success_num` int(11) NOT NULL DEFAULT '0',
  `fail_num` int(11) NOT NULL DEFAULT '0',
  `task_num` int(11) NOT NULL,
  `used_time` int(11) NOT NULL,
  `start_time` datetime NOT NULL,
  `end_time` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
  PRIMARY KEY (`id`),
  KEY `task_id` (`task_id`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 COMMENT='备份' AUTO_INCREMENT=77 ;

-- --------------------------------------------------------

--
-- 表的结构 `devicePassword`
--

CREATE TABLE IF NOT EXISTS `devicePassword` (
  `deviceId` varchar(32) NOT NULL,
  `vector` text NOT NULL,
  `password` text NOT NULL,
  `idc` varchar(128) CHARACTER SET utf8 NOT NULL,
  `business` varchar(128) CHARACTER SET utf8 NOT NULL,
  PRIMARY KEY (`deviceId`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- --------------------------------------------------------

--
-- 表的结构 `sInstanceNet`
--

CREATE TABLE IF NOT EXISTS `sInstanceNet` (
  `instanceId` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `ip` varchar(64) CHARACTER SET latin1 COLLATE latin1_general_ci NOT NULL,
  `packagePath` varchar(128) CHARACTER SET latin1 COLLATE latin1_general_ci NOT NULL,
  `packageVersion` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `installPath` varchar(255) CHARACTER SET latin1 COLLATE latin1_general_ci DEFAULT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `port` varchar(32) COLLATE utf8_unicode_ci NOT NULL,
  `submitTime` datetime DEFAULT NULL,
  `installTime` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `billId` int(10) DEFAULT NULL,
  `lastOperation` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `lastErrmsg` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `startStopResult` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `status` int(11) DEFAULT NULL,
  `user` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `lastVersion` varchar(64) COLLATE utf8_unicode_ci DEFAULT NULL,
  `t_flag` int(11) NOT NULL,
  PRIMARY KEY (`instanceId`),
  UNIQUE KEY `ip_2` (`ip`,`packagePath`,`installPath`),
  KEY `ip` (`ip`),
  KEY `billId` (`billId`),
  KEY `packagePath` (`packagePath`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=88 ;

-- --------------------------------------------------------

--
-- 表的结构 `sPackage`
--

CREATE TABLE IF NOT EXISTS `sPackage` (
  `packageId` int(11) NOT NULL AUTO_INCREMENT,
  `billId` int(10) DEFAULT NULL,
  `product` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `name` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `version` varchar(255) COLLATE utf8_unicode_ci NOT NULL,
  `path` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `svnVersion` int(11) DEFAULT NULL,
  `tag` varchar(256) COLLATE utf8_unicode_ci NOT NULL,
  `user` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `author` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `stateless` enum('true','false','undefined') COLLATE utf8_unicode_ci DEFAULT NULL,
  `os` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `frameworkType` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,
  `submitTime` datetime DEFAULT NULL,
  `lastModify` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `lastRelease` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT '??????',
  `releaseOperater` varchar(32) COLLATE utf8_unicode_ci NOT NULL COMMENT '???',
  `lastCompile` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT '??????',
  `compileOperator` varchar(32) COLLATE utf8_unicode_ci NOT NULL COMMENT '???',
  `remark` text COLLATE utf8_unicode_ci,
  `status` int(10) DEFAULT NULL,
  KEY `id` (`packageId`)
) ENGINE=MyISAM  DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci AUTO_INCREMENT=25 ;

-- --------------------------------------------------------

--
-- 表的结构 `t_PkgAttribute`
--

CREATE TABLE IF NOT EXISTS `t_PkgAttribute` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `public` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `pkg_bid` (`product`,`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=6 ;

-- --------------------------------------------------------

--
-- 表的结构 `t_PkgRole`
--

CREATE TABLE IF NOT EXISTS `t_PkgRole` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `user_name` varchar(50) NOT NULL,
  `role` varchar(50) NOT NULL,
  `status` int(11) NOT NULL,
  `validity_time` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `pkg_bid` (`product`,`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=18 ;

-- --------------------------------------------------------

--
-- 表的结构 `t_PkgRole_1`
--

CREATE TABLE IF NOT EXISTS `t_PkgRole_1` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `product` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `user_name` varchar(50) NOT NULL,
  `role` varchar(50) NOT NULL,
  `status` int(11) NOT NULL,
  `validity_time` date NOT NULL,
  PRIMARY KEY (`id`),
  KEY `pkg_bid` (`product`,`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;

-- --------------------------------------------------------

--
-- 表的结构 `t_RolePower`
--

CREATE TABLE IF NOT EXISTS `t_RolePower` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `role` varchar(50) NOT NULL,
  `privilege` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `role_id` (`role`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=8 ;

-- --------------------------------------------------------

--
-- 表的结构 `t_Token`
--

CREATE TABLE IF NOT EXISTS `t_Token` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(32) NOT NULL,
  `token` varchar(64) NOT NULL,
  `expireTime` datetime NOT NULL,
  `updateTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=77 ;

-- --------------------------------------------------------

--
-- 表的结构 `t_User`
--

CREATE TABLE IF NOT EXISTS `t_User` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(50) NOT NULL,
  `role` varchar(16) NOT NULL,
  `password` varchar(50) NOT NULL,
  `salt` varchar(64) NOT NULL,
  `regTime` datetime NOT NULL,
  `updateTime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_name` (`username`)
) ENGINE=InnoDB  DEFAULT CHARSET=utf8 AUTO_INCREMENT=16 ;

-- --------------------------------------------------------

--
-- 表的结构 `test`
--

CREATE TABLE IF NOT EXISTS `test` (
  `name` varchar(16) NOT NULL,
  `password` varchar(16) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;

INSERT INTO `t_User` (`id`, `username`, `role`, `password`, `salt`, `regTime`, `updateTime`) VALUES
(1, 'admin', 'admin', 'b3b7f32a45b321fa6757d86110956a8e9c45eaf9', 'ZTM5M2Y2YjEyMjRlYjZhYTg0NWI4MDZlYjM1Y2Q4MGQ=', '2015-04-08 10:56:54', '2015-04-14 06:49:10');


INSERT INTO `t_User` (`id`, `username`, `role`, `password`, `salt`, `regTime`, `updateTime`) VALUES
(2, 'guest', 'user', '916f674d23a0b9e616fa83bfb686589555f7684c', 'YmQ1Y2ZkYzAyNzI3ZTlmNThkOWM3ZDRiZTg5ZTAyYTQ=', '2015-04-08 10:56:54', '2015-04-14 06:49:10');

INSERT INTO `ProductNameMap` (`id`, `product`, `chinese`) VALUES
(1, 'default', '默认');

INSERT INTO `t_RolePower` (`id`, `role`, `privilege`) VALUES
(1, 'admin', 'admin'),
(2, 'developer', 'develop'),
(5, 'operator', 'operate'),
(6, 'super_operator', 'operate'),
(7, 'super_operator', 'super_operate');


--
-- 数据库: `TARS`
--

CREATE DATABASE `TARS` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;
USE `TARS`;

-- --------------------------------------------------------
--
-- 表的结构 `pkg_default`
--

CREATE TABLE IF NOT EXISTS `pkg_default` (
  `task_id` varchar(100) DEFAULT NULL,
  `task_status` varchar(100) DEFAULT NULL,
  `ip` varchar(100) DEFAULT NULL,
  `password` varchar(100) DEFAULT NULL,
  `input_cmd` varchar(1000) DEFAULT NULL,
  `user_name` varchar(100) DEFAULT NULL,
  `ret_code` int(11) NOT NULL DEFAULT '0',
  `result` mediumtext,
  `timeout` int(11) DEFAULT NULL,
  `start_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00',
  `end_time` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' ON UPDATE CURRENT_TIMESTAMP,
  `server_ip` varchar(100) DEFAULT NULL,
  KEY `task_id` (`task_id`),
  KEY `ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
