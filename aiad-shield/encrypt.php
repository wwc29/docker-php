<?php

include_once __DIR__ . '/FileUtil.php';

$file = $argv[1];

$list = FileUtil::scanDirectory($file)['files'];
foreach ($list as $file) {
    if ($fp = fopen($file, 'rb+') and $fileSize = filesize($file)) {
        $data = aiadenc_encode(fread($fp, $fileSize));
        if ($data !== false) {
            if (file_put_contents($file, '') !== false) {
                rewind($fp); //将文件指针的位置倒回文件的开头
                fwrite($fp, $data);
            }
        }
        fclose($fp);
    }
}
