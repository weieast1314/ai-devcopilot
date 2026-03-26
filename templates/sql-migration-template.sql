-- =====================================================
-- SQL 迁移脚本
-- 需求: {需求标题}
-- Issue: #{issue-id}
-- 日期: {YYYY-MM-DD}
-- 作者: {author}
-- =====================================================

-- -----------------------------------------------------
-- 表结构变更
-- -----------------------------------------------------

-- 新增表: t_xxx
CREATE TABLE IF NOT EXISTS `t_xxx` (
    `id` BIGINT(20) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
    `name` VARCHAR(100) NOT NULL COMMENT '名称',
    `status` TINYINT(1) DEFAULT 1 COMMENT '状态: 1-有效, 0-无效',
    `created_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `last_modified_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '修改时间',
    PRIMARY KEY (`id`),
    KEY `idx_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='表说明';

-- -----------------------------------------------------
-- 数据变更
-- -----------------------------------------------------

-- 插入初始数据
-- INSERT INTO `t_xxx` (`name`, `status`) VALUES ('xxx', 1);

-- -----------------------------------------------------
-- 回滚脚本 (如需要)
-- -----------------------------------------------------

/*
-- 回滚: 删除表
DROP TABLE IF EXISTS `t_xxx`;
*/
