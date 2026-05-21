import multer, { FileFilterCallback } from 'multer';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { Request } from 'express';
import { ApiError } from '../utils/ApiError';

const UPLOAD_DIR = process.env.UPLOAD_DIR ?? './uploads';
const MAX_SIZE_MB = parseInt(process.env.MAX_FILE_SIZE_MB ?? '5', 10);
const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp'];

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, UPLOAD_DIR);
  },
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `${uuidv4()}${ext}`);
  },
});

function imageFilter(_req: Request, file: Express.Multer.File, cb: FileFilterCallback) {
  if (ALLOWED_IMAGE_TYPES.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(ApiError.badRequest('Допустимые форматы изображений: JPEG, PNG, WebP'));
  }
}

export const uploadAvatar = multer({
  storage,
  fileFilter: imageFilter,
  limits: { fileSize: MAX_SIZE_MB * 1024 * 1024 },
}).single('avatar');
