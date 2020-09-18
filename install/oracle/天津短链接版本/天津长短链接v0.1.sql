-- drop table TD_GATEWAY_NODE cascade constraints;

/*==============================================================*/
/* Table: TD_GATEWAY_NODE                                       */
/*==============================================================*/
create table TD_GATEWAY_NODE 
(
   ID                   VARCHAR2(32 CHAR)    not null,
   IP                   VARCHAR2(255 CHAR) not null,
   port               VARCHAR2(20 CHAR) not null,
   REMARKS              VARCHAR2(255 CHAR),
   CREATE_DATE          DATE,
   CREATE_BY            VARCHAR2(255 CHAR),
   UPDATE_DATE          DATE,
   UPDATE_BY            VARCHAR2(255 CHAR),
   STATUS               CHAR(1 CHAR),
   internal_port      VARCHAR2(20 CHAR) not null,
   constraint PK_TD_GATEWAY_NODE primary key (ID)
);

comment on table TD_GATEWAY_NODE is
'节点管理表';

comment on column TD_GATEWAY_NODE.ID is
'主键';

comment on column TD_GATEWAY_NODE.IP is
'IP';

comment on column TD_GATEWAY_NODE.port is
'PORT';

comment on column TD_GATEWAY_NODE.REMARKS is
'描述';

comment on column TD_GATEWAY_NODE.CREATE_DATE is
'创建时间';

comment on column TD_GATEWAY_NODE.CREATE_BY is
'创建人';

comment on column TD_GATEWAY_NODE.UPDATE_DATE is
'修改时间';

comment on column TD_GATEWAY_NODE.UPDATE_BY is
'修改人';

comment on column TD_GATEWAY_NODE.STATUS is
'状态';

comment on column TD_GATEWAY_NODE.internal_port is
'对内端口';


-- drop table TD_Links_convert cascade constraints;

/*==============================================================*/
/* Table: "TD_Links_convert"                                    */
/*==============================================================*/
create table TD_Links_convert 
(
   ID                   VARCHAR2(32 CHAR)    not null,
   long_link          VARCHAR2(1000 CHAR)  not null,
   short_link        VARCHAR2(1000 CHAR)  not null,
   param              VARCHAR2(1000 CHAR)  not null,
   CREATE_DATE          DATE,
   CREATE_BY            VARCHAR2(255 CHAR),
   UPDATE_DATE          DATE,
   UPDATE_BY            VARCHAR2(255 CHAR),
   REMARKS              VARCHAR2(255 CHAR),
   channel            VARCHAR2(255 CHAR) not null,
   proposer           VARCHAR2(50 CHAR) not null,
   Apply_department   VARCHAR2(50 CHAR) not null,
   whether_param      CHAR(1 CHAR) not null,
   deal_type          VARCHAR2(32 CHAR) not null,
   constraint PK_TD_LINKS_CONVERT primary key (ID)
);

comment on table TD_Links_convert is
'链接转换表';

comment on column TD_Links_convert.ID is
'主键';

comment on column TD_Links_convert.long_link is
'长链接';

comment on column TD_Links_convert.short_link is
'短链接';

comment on column TD_Links_convert.param is
'参数';

comment on column TD_Links_convert.CREATE_DATE is
'创建时间';

comment on column TD_Links_convert.CREATE_BY is
'创建人';

comment on column TD_Links_convert.UPDATE_DATE is
'修改时间';

comment on column TD_Links_convert.UPDATE_BY is
'修改人';

comment on column TD_Links_convert.REMARKS is
'说明';

comment on column TD_Links_convert.channel is
'渠道';

comment on column TD_Links_convert.proposer is
'申请人';

comment on column TD_Links_convert.Apply_department is
'申请部门';

comment on column TD_Links_convert.whether_param is
'是否带参';

comment on column TD_Links_convert.deal_type is
'协议类型';


-- drop table TD_LINKS_PARAM cascade constraints;

/*==============================================================*/
/* Table: TD_LINKS_PARAM                                        */
/*==============================================================*/
create table TD_LINKS_PARAM 
(
   ID                   VARCHAR2(32 CHAR)    not null,
   column_name        VARCHAR2(50 CHAR)    not null,
   Column_value       VARCHAR2(500 CHAR)   not null,
   link_id            VARCHAR2(32 CHAR)    not null,
   constraint PK_TD_LINKS_PARAM primary key (ID)
);

comment on table TD_LINKS_PARAM is
'链接转换字段表';

comment on column TD_LINKS_PARAM.ID is
'主键';

comment on column TD_LINKS_PARAM.column_name is
'字段名';

comment on column TD_LINKS_PARAM.Column_value is
'字段值';

comment on column TD_LINKS_PARAM.link_id is
'字段反转记录ID';
