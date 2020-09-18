/*
 Navicat Premium Data Transfer

 Source Server         : paastest
 Source Server Type    : Oracle
 Source Server Version : 110200
 Source Host           : 10.10.149.4:1521
 Source Schema         : asgyyt

 Target Server Type    : Oracle
 Target Server Version : 110200
 File Encoding         : 65001

 Date: 09/09/2020 09:43:59
*/

CREATE TABLE "asgyyt"."TF_GATEWAY_RULESET_DETAIL" (
  "ID" VARCHAR2(32 BYTE) NOT NULL ,
  "NAME" VARCHAR2(20 BYTE) ,
  "ENABLE" VARCHAR2(5 BYTE) ,
  "TIME" TIMESTAMP(6) DEFAULT sysdate   ,
  "JUDGE" NVARCHAR2(500) ,
  "HANDLE" NVARCHAR2(500) 
)

-- ----------------------------
-- Records of TF_GATEWAY_RULESET_DETAIL
-- ----------------------------
INSERT INTO "asgyyt"."TF_GATEWAY_RULESET_DETAIL" VALUES ('5976e1f5fd9d4d64a90bce74c7092969', '电渠ip拦截', 'true', NULL, '{"conditions":[{"type":"IP","operator":"in","value":"[ ''10.4.0.13'',''192.168.56.1'', ''10.10.143.125'']"}],"type":1}', '{"log":true,"continue":true}');
INSERT INTO "asgyyt"."TF_GATEWAY_RULESET_DETAIL" VALUES ('216e1f3dd82542039bbd85317b3d0b07', '全渠道ip拦截', 'true', NULL, '{"conditions":[{"type":"IP","value":"[''10.4.0.13'']","operator":"!="}],"type":1}', '{"log":true,"continue":true}');
INSERT INTO "asgyyt"."TF_GATEWAY_RULESET_DETAIL" VALUES ('621edc325f264f48ab5e4d1cc5dc31af', 'h5', 'true', NULL, '{"conditions":[{"type":"IP","operator":"in","value":"[''10.10.143.83'', ''10.10.143.125'']"}],"type":1}', '{"log":true,"continue":true}');


CREATE TABLE "asgyyt"."TF_GATEWAY_RULESET_RESOURCE" (
  "ID" VARCHAR2(32 BYTE) NOT NULL ,
  "RTYPE" VARCHAR2(50 BYTE) ,
  "RNAME" VARCHAR2(50 BYTE) ,
  "RVALUE" VARCHAR2(255 BYTE) ,
  "RDESC" VARCHAR2(255 BYTE) ,
  "CREATE_TIME" TIMESTAMP(6) DEFAULT sysdate      ,
  "STATUS" NUMBER DEFAULT 0  
 
)


-- ----------------------------
-- Records of TF_GATEWAY_RULESET_RESOURCE
-- ----------------------------
INSERT INTO "asgyyt"."TF_GATEWAY_RULESET_RESOURCE" VALUES ('923230a1df3e459aa7e2b5e5c6ae2887', 'IP', '测试白名单ip', '10.21.20.172', '测试白名单组12345', TO_TIMESTAMP('2020-08-24 18:17:53.000000', 'SYYYY-MM-DD HH24:MI:SS:FF6'), '0');
INSERT INTO "asgyyt"."TF_GATEWAY_RULESET_RESOURCE" VALUES ('93fa97219fe749ef9af5514111e91bec', 'IP', '测试白名单', '192.168.56.110', '测试白名单', TO_TIMESTAMP('2020-08-25 10:13:59.000000', 'SYYYY-MM-DD HH24:MI:SS:FF6'), '0');
INSERT INTO "asgyyt"."TF_GATEWAY_RULESET_RESOURCE" VALUES ('f5e91ff531b34c768d9aed9a58cdd2f6', 'HOSTNAME', '域名白名单', 'www.10086.hn', 'qqq', TO_TIMESTAMP('2020-08-25 10:14:28.000000', 'SYYYY-MM-DD HH24:MI:SS:FF6'), '0');
INSERT INTO "asgyyt"."TF_GATEWAY_RULESET_RESOURCE" VALUES ('529b541c316240cc87369c6911cd9103', 'HOSTNAME', '域名白名单', 'www.baidu.com', '123', TO_TIMESTAMP('2020-08-25 10:14:41.000000', 'SYYYY-MM-DD HH24:MI:SS:FF6'), '0');


CREATE TABLE "asgyyt"."TF_GATEWAY_SYSRULE" (
  "ID" VARCHAR2(32 BYTE) NOT NULL ,
  "NAME" VARCHAR2(20 BYTE) ,
  "ENABLE" VARCHAR2(5 BYTE) ,
  "TIME" TIMESTAMP(6) DEFAULT sysdate     ,
  "JUDGE" NVARCHAR2(500) ,
  "HANDLE" NVARCHAR2(500) ,
  "TYPE" NUMBER ,
  "RULES" VARCHAR2(255 BYTE) 
)


-- ----------------------------
-- Records of TF_GATEWAY_SYSRULE
-- ----------------------------
INSERT INTO "asgyyt"."TF_GATEWAY_SYSRULE" VALUES ('ba6ae148d8bd492bba2ba8119132adee', '电渠系统', 'true', TO_TIMESTAMP('2020-09-07 09:31:23.309000', 'SYYYY-MM-DD HH24:MI:SS:FF6'), '{"type":1,"conditions":[{"value":"/a","operator":"match","type":"URI"}]}', '{"log":true,"continue":true}', '0', '["5976e1f5fd9d4d64a90bce74c7092969"]');
INSERT INTO "asgyyt"."TF_GATEWAY_SYSRULE" VALUES ('e438b365246b4800ac400f45595ca392', '全部', 'true', TO_TIMESTAMP('2020-09-01 18:17:01.582000', 'SYYYY-MM-DD HH24:MI:SS:FF6'), '{"type":1,"conditions":[{"value":"/","operator":"match","type":"URI"}]}', '{"log":true,"continue":true}', '0', '["216e1f3dd82542039bbd85317b3d0b07"]');
INSERT INTO "asgyyt"."TF_GATEWAY_SYSRULE" VALUES ('08615053f63c43bcbc627895d1563ba1', 'h5', 'true', TO_TIMESTAMP('2020-09-07 09:32:47.487000', 'SYYYY-MM-DD HH24:MI:SS:FF6'), '{"type":1,"conditions":[{"value":"/h5","operator":"match","type":"URI"}]}', '{"log":true,"continue":true}', '0', '["621edc325f264f48ab5e4d1cc5dc31af"]');



-- ----------------------------
-- Primary Key structure for table TF_GATEWAY_RULESET_DETAIL
-- ----------------------------
ALTER TABLE "asgyyt"."TF_GATEWAY_RULESET_DETAIL" ADD CONSTRAINT "SYS_C00158261" PRIMARY KEY ("ID");

-- ----------------------------
-- Checks structure for table TF_GATEWAY_RULESET_DETAIL
-- ----------------------------
ALTER TABLE "asgyyt"."TF_GATEWAY_RULESET_DETAIL" ADD CONSTRAINT "SYS_C00126399" CHECK ("ID" IS NOT NULL) NOT DEFERRABLE INITIALLY IMMEDIATE NORELY VALIDATE;
ALTER TABLE "asgyyt"."TF_GATEWAY_RULESET_DETAIL" ADD CONSTRAINT "SYS_C00158260" CHECK ("ID" IS NOT NULL) NOT DEFERRABLE INITIALLY IMMEDIATE NORELY VALIDATE;

-- ----------------------------
-- Primary Key structure for table TF_GATEWAY_RULESET_RESOURCE
-- ----------------------------
ALTER TABLE "asgyyt"."TF_GATEWAY_RULESET_RESOURCE" ADD CONSTRAINT "SYS_C00159460" PRIMARY KEY ("ID");

-- ----------------------------
-- Checks structure for table TF_GATEWAY_RULESET_RESOURCE
-- ----------------------------
ALTER TABLE "asgyyt"."TF_GATEWAY_RULESET_RESOURCE" ADD CONSTRAINT "SYS_C00126400" CHECK ("ID" IS NOT NULL) NOT DEFERRABLE INITIALLY IMMEDIATE NORELY VALIDATE;
ALTER TABLE "asgyyt"."TF_GATEWAY_RULESET_RESOURCE" ADD CONSTRAINT "SYS_C00159459" CHECK ("ID" IS NOT NULL) NOT DEFERRABLE INITIALLY IMMEDIATE NORELY VALIDATE;


-- ----------------------------
-- Primary Key structure for table TF_GATEWAY_SYSRULE
-- ----------------------------
ALTER TABLE "asgyyt"."TF_GATEWAY_SYSRULE" ADD CONSTRAINT "SYS_C00160123" PRIMARY KEY ("ID");

-- ----------------------------
-- Checks structure for table TF_GATEWAY_SYSRULE
-- ----------------------------
ALTER TABLE "asgyyt"."TF_GATEWAY_SYSRULE" ADD CONSTRAINT "SYS_C00126408" CHECK ("ID" IS NOT NULL) NOT DEFERRABLE INITIALLY IMMEDIATE NORELY VALIDATE;
ALTER TABLE "asgyyt"."TF_GATEWAY_SYSRULE" ADD CONSTRAINT "SYS_C00158259" CHECK ("ID" IS NOT NULL) NOT DEFERRABLE INITIALLY IMMEDIATE NORELY VALIDATE;

